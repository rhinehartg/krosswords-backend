require 'net/http'
require 'uri'
require 'json'

class AiGeneratorService
  class Error < StandardError; end
  class ApiError < Error; end
  class ParseError < Error; end

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :api_key, :string
  attribute :api_url, :string, default: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent'
  attribute :timeout, :integer, default: 30
  attribute :max_retries, :integer, default: 3
  attribute :retry_delay, :integer, default: 1
  attribute :fit_attempts, :integer, default: 6
  attribute :min_fit_tolerance, :integer, default: 0

  # AI Generation limits by tier
  QUOTAS = {
    'FREE' => 5,     # 5 AI generations for free tier
    'PRO' => 3,     # 3 AI puzzles per day for Pro
    'PREMIUM' => -1 # Unlimited for Premium (-1 means unlimited)
  }.freeze

  # Generation configuration
  GENERATION_CONFIG = {
    temperature: 0.6,
    max_output_tokens: 2048,
    response_mime_type: "application/json"
  }.freeze

  # Default prompt template for puzzle generation
  # Header built from input parameters
  DEFAULT_PROMPT_TEMPLATE = <<~PROMPT
    Generate a crossword word list.

    - Theme: {theme}
    - Difficulty: {requested_difficulty}
    - Target words: at least {word_count}, up to {word_count_plus_two}
  PROMPT

  # Guidance appended after the header (can be overridden via GEMINI_PROMPT_GUIDANCE)
  DEFAULT_PROMPT_GUIDANCE = <<~GUIDE
    Rules:
    - Each answer is 3-12 letters, UPPERCASE A-Z only.
    - Each clue is concise (5-50 chars) and clearly related to the theme.

    Return ONLY this JSON (no extra text):
    {
      "title": "Puzzle Title",
      "description": "Brief description",
      "difficulty": "{requested_difficulty}",
      "words": [
        {"clue": "Clue text", "answer": "ANSWER"}
      ]
    }
  GUIDE

  def initialize(api_key: nil)
    super()
    @api_key = api_key || ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key
    @api_url = ENV['GEMINI_API_URL'].presence || api_url
    @generation_config = {
      temperature: (ENV['GEMINI_TEMPERATURE']&.to_f || GENERATION_CONFIG[:temperature]),
      max_output_tokens: (ENV['GEMINI_MAX_OUTPUT_TOKENS']&.to_i || GENERATION_CONFIG[:max_output_tokens]),
      response_mime_type: GENERATION_CONFIG[:response_mime_type]
    }
    @fit_attempts = (ENV['CROSSWORD_FIT_ATTEMPTS']&.to_i || fit_attempts)
    @min_fit_tolerance = (ENV['MIN_FIT_TOLERANCE']&.to_i || min_fit_tolerance)
    raise Error, "Missing Gemini API key" if @api_key.blank?
  end

  # Generate a puzzle using AI
  def generate_puzzle(request_params)
    puts "=== AI GENERATOR SERVICE: generate_puzzle CALLED ==="
    puts "Request params: #{request_params.inspect}"
    
    validate_request!(request_params)
    
    begin
      puts "=== BUILDING PROMPT ==="
      prompt = build_prompt(request_params)
      puts "Prompt: #{prompt}"

      # Basic retry loop for response quality issues
      attempts = 0
      max_attempts = (ENV['GEMINI_MAX_RETRIES']&.to_i || max_retries)
      last_error = nil
      begin
        attempts += 1
        puts "=== CALLING GEMINI API (attempt #{attempts}/#{max_attempts}) ==="
        response = call_gemini_api(prompt)
        puts "Gemini response received"

        puts "=== PARSING AI RESPONSE ==="
        puzzle_data = parse_ai_response(response, request_params)

        # parse_ai_response now filters invalid words and ensures minimum count
        
        # Try to fit as many words as possible before creating
        requested_words = request_params[:word_count].to_i
        puts "=== FITTING WORDS INTO CROSSWORD GRID ==="
        fitted_clues = validate_and_trim_clues(puzzle_data[:clues], requested_words)
        min_acceptable = [requested_words - @min_fit_tolerance, 3].max
        if fitted_clues.length < min_acceptable
          raise ParseError, "Too few words fit the grid (#{fitted_clues.length} < #{min_acceptable})"
        end
        puzzle_data[:clues] = fitted_clues
      rescue Error => e
        last_error = e
        if attempts < max_attempts
          sleep(retry_delay)
          retry
        else
          raise
        end
      end
      puts "Puzzle data parsed: #{puzzle_data.inspect}"
      
      # Create and save the puzzle
      puts "=== CREATING PUZZLE RECORD ==="
      puzzle = create_puzzle_record(puzzle_data)
      puts "Puzzle created: #{puzzle.id}"
      
      {
        success: true,
        puzzle: puzzle,
        error: nil
      }
    rescue Error => e
      puts "=== AI GENERATOR ERROR ==="
      puts "Error: #{e.message}"
      puts "Error class: #{e.class}"
      Rails.logger.error "AI Generator Error: #{e.message}"
      {
        success: false,
        puzzle: nil,
        error: e.message
      }
    end
  end

  # Check if AI is available
  def self.available?
    ENV['GEMINI_API_KEY'].present? || Rails.application.credentials.gemini_api_key.present?
  end

  # Get quota for user tier
  def self.get_quota(user_tier)
    QUOTAS[user_tier.to_s.upcase] || 0
  end

  # Check if user has remaining quota
  def self.has_quota?(user_tier, used_count = 0)
    quota = get_quota(user_tier)
    return true if quota == -1 # Unlimited
    used_count < quota
  end

  # Get the current prompt template being used
  def self.current_prompt_template
    ENV['GEMINI_PROMPT_TEMPLATE'] || DEFAULT_PROMPT_TEMPLATE
  end

  # Check if using custom prompt template
  def self.using_custom_prompt?
    ENV['GEMINI_PROMPT_TEMPLATE'].present?
  end

  private

  def validate_request!(params)
    puts "=== VALIDATING REQUEST ==="
    puts "Params: #{params.inspect}"
    puts "API key present: #{@api_key.present?}"
    puts "API key length: #{@api_key&.length}"
    
    unless params[:prompt].present? && params[:prompt].length >= 3
      puts "ERROR: Prompt validation failed"
      raise Error, 'Prompt must be at least 3 characters long'
    end

    unless params[:word_count].present? && (5..15).cover?(params[:word_count])
      puts "ERROR: Word count validation failed"
      raise Error, 'Word count must be between 5 and 15'
    end

    unless %w[Easy Medium Hard].include?(params[:difficulty])
      puts "ERROR: Difficulty validation failed"
      raise Error, 'Difficulty must be Easy, Medium, or Hard'
    end

    unless @api_key.present? && @api_key.length > 20
      puts "ERROR: API key validation failed"
      raise Error, 'Invalid or missing Gemini API key'
    end
    
    puts "=== VALIDATION PASSED ==="
  end

  def build_prompt(params)
    # Header from inputs
    header_template = DEFAULT_PROMPT_TEMPLATE
    # Optional guidance from environment, otherwise default guidance
    guidance_template = ENV['GEMINI_PROMPT_GUIDANCE'].presence || DEFAULT_PROMPT_GUIDANCE

    # Use theme if provided, otherwise use prompt as theme
    theme = params[:theme].present? ? params[:theme] : params[:prompt]

    substitutions = {
      '{theme}' => theme,
      '{requested_difficulty}' => params[:difficulty],
      '{word_count}' => params[:word_count].to_s,
      '{word_count_plus_two}' => (params[:word_count].to_i + 2).to_s
    }

    header = substitutions.reduce(header_template) { |acc, (k, v)| acc.gsub(k, v) }
    guidance = substitutions.reduce(guidance_template) { |acc, (k, v)| acc.gsub(k, v) }
    [header, guidance].join("\n\n")
  end

  def call_gemini_api(prompt)
    uri = URI("#{@api_url}?key=#{@api_key}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
    http.read_timeout = timeout
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    request_body = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: @generation_config
    }
    
    request.body = request_body.to_json
    
    Rails.logger.debug "AI Generator: Making API request to #{uri.host}"
    response = http.request(request)
    
    Rails.logger.debug "AI Generator: API Response status: #{response.code}"
    
    unless response.code == '200'
      raise ApiError, "API request failed with status #{response.code}: #{response.body}"
    end
    
    parsed_response = JSON.parse(response.body)
    parse_gemini_response(parsed_response)
  end

  def parse_gemini_response(parsed_data)
    Rails.logger.debug "AI Generator: Parsing response data with keys: #{parsed_data.keys.inspect}"

    unless parsed_data["candidates"]&.any?
      Rails.logger.warn "AI Generator: No candidates found in response"
      raise ParseError, "No candidates found in AI response"
    end

    text = parsed_data.dig("candidates", 0, "content", "parts", 0, "text")
    Rails.logger.debug "AI Generator: Extracted text length: #{text&.length}"

    text.to_s.strip
  rescue JSON::ParserError => e
    Rails.logger.error "AI Generator: JSON parsing failed: #{e.message}"
    raise ParseError, "Failed to parse Gemini response: #{e.message}"
  end

  def parse_ai_response(text, request_params)
    # Clean the response text
    cleaned_text = text
      .gsub(/```json\n?/, '')
      .gsub(/```\n?/, '')
      .strip

    # Find JSON object in the response
    json_match = cleaned_text.match(/\{[\s\S]*\}/)
    unless json_match
      raise ParseError, 'No valid JSON found in AI response'
    end

    json_text = json_match[0]
    parsed = JSON.parse(json_text)

    # Validate the response structure
    unless parsed['words'].is_a?(Array)
      raise ParseError, 'Invalid puzzle structure: missing words array'
    end

    # Filter and validate words - log invalid ones but don't fail immediately
    words = []
    invalid_words = []
    
    parsed['words'].each.with_index do |word, index|
      begin
        validate_word!(word, index)
        words << {
          'clue' => word['clue'].strip,
          'answer' => word['answer'].strip.upcase
        }
      rescue ParseError => e
        invalid_words << {
          index: index,
          clue: word['clue'],
          answer: word['answer'],
          error: e.message,
          length: word['answer']&.length
        }
        Rails.logger.warn "AI Generator: Filtered invalid word at index #{index}: #{word['answer']} (#{word['answer']&.length} letters) - #{e.message}"
      end
    end
    
    # Log if we filtered any words
    if invalid_words.any?
      Rails.logger.warn "AI Generator: Filtered #{invalid_words.length} invalid word(s) from #{parsed['words'].length} total"
      invalid_words.each do |inv|
        puts "  - Index #{inv[:index]}: '#{inv[:answer]}' (#{inv[:length]} letters): #{inv[:error]}"
      end
    end
    
    # Ensure we still have enough valid words
    min_words = request_params[:word_count].to_i
    if words.length < min_words
      raise ParseError, "After filtering invalid words, only #{words.length} valid words remain (need at least #{min_words}). Invalid words: #{invalid_words.map { |w| "'#{w[:answer]}' (#{w[:length]} letters)" }.join(', ')}"
    end

    {
      title: parsed['title'] || "AI Generated Puzzle - #{request_params[:theme] || 'General'}",
      description: parsed['description'] || "An AI-generated #{request_params[:difficulty].downcase} puzzle",
      difficulty: parsed['difficulty'] || request_params[:difficulty],
      clues: words
    }
  rescue JSON::ParserError => e
    Rails.logger.error "AI Generator: JSON parsing failed in parse_ai_response: #{e.message}"
    raise ParseError, "Failed to parse AI response: #{e.message}"
  end

  def validate_word!(word, index)
    unless word['clue'].present? && word['answer'].present?
      raise ParseError, "Invalid word at index #{index}: missing clue or answer"
    end

    unless word['clue'].is_a?(String) && word['answer'].is_a?(String)
      raise ParseError, "Invalid word at index #{index}: clue and answer must be strings"
    end

    # Normalize answer to uppercase for validation
    answer = word['answer'].strip.upcase
    
    # Validate answer format - letters only (we'll normalize to uppercase)
    unless /^[A-Za-z]+$/.match?(word['answer'])
      raise ParseError, "Invalid word at index #{index}: answer must be letters only (A-Z, no spaces, hyphens, or special characters)"
    end

    unless (3..12).cover?(answer.length)
      raise ParseError, "Invalid word at index #{index}: answer '#{answer}' must be 3-12 letters long (got #{answer.length})"
    end
  end

  def create_puzzle_record(puzzle_data)
    # Convert difficulty to title case for model validation
    difficulty = case puzzle_data[:difficulty].to_s.upcase
                when 'EASY' then 'Easy'
                when 'MEDIUM' then 'Medium'
                when 'HARD' then 'Hard'
                else 'Medium'
                end
    
    # Validate and trim clues to ensure they fit in a crossword grid
    validated_clues = validate_and_trim_clues(puzzle_data[:clues])
    
    Puzzle.create!(
      title: puzzle_data[:title],
      description: puzzle_data[:description],
      difficulty: difficulty,
      rating: determine_rating(puzzle_data[:difficulty]),
      clues: validated_clues,
      is_published: true # AI-generated puzzles are published by default
    )
  end

  def determine_rating(difficulty)
    case difficulty.to_s.downcase
    when 'easy' then 1
    when 'medium' then 2
    when 'hard' then 3
    else 2 # Default to medium
    end
  end

  def validate_and_trim_clues(clues, desired_count = nil)
    return clues if clues.empty?
    
    # Try to generate a crossword layout with all clues
    crossword_service = CrosswordGeneratorService.new
    layout_result = crossword_service.generate_layout(clues)
    
    # If all words fit, return the original clues
    if layout_result[:result].length == clues.length
      puts "All #{clues.length} clues fit in the crossword grid"
      return clues
    end
    
    # If not all words fit, search for the largest fitting subset with multiple shuffles
    puts "Only #{layout_result[:result].length} out of #{clues.length} clues fit in the grid"
    puts "Attempting to trim clues to fit..."

    best_subset = []
    attempts = 0
    max_attempts = @fit_attempts
    target = desired_count || clues.length

    while attempts < max_attempts
      attempts += 1
      try_clues = clues.shuffle
      # Prefer meeting the desired count (or close), then decrease
      start_count = [try_clues.length, target].min
      start_count.downto(3) do |count|
        subset = try_clues.first(count)
        result = crossword_service.generate_layout(subset)
        if result[:result].length == count
          puts "Successfully fitted #{count} clues in the grid (attempt #{attempts})"
          return subset
        end
        best_subset = subset if result[:result].length > best_subset.length
      end
    end

    if best_subset.any?
      puts "Using best found subset of size #{best_subset.length}"
      return best_subset
    end

    # Fallback: use any successfully fitted words from the initial attempt, else first 3
    fitted_words = layout_result[:result].map { |word| clues.find { |clue| clue['answer'] == word['answer'] } }.compact
    return fitted_words if fitted_words.length >= 3

    puts "Falling back to first 3 clues"
    clues.first(3)
  end
end
