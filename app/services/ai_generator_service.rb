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

  # AI Generation limits by tier
  QUOTAS = {
    'FREE' => 5,     # 5 AI generations for free tier
    'PRO' => 3,     # 3 AI puzzles per day for Pro
    'PREMIUM' => -1 # Unlimited for Premium (-1 means unlimited)
  }.freeze

  # Generation configuration
  GENERATION_CONFIG = {
    temperature: 0.7,
    max_output_tokens: 1024,
    response_mime_type: "application/json"
  }.freeze

  # Default prompt template for puzzle generation
  DEFAULT_PROMPT_TEMPLATE = <<~PROMPT
    Create a {requested_difficulty} crossword puzzle about "{theme}" with approximately {word_count} words.

    Requirements:
    - Words: 3-12 letters, UPPERCASE letters only (A-Z, no accented characters)
    - Words must intersect naturally in a crossword grid
    - Use everyday vocabulary appropriate for the theme
    - Clues should be clear and engaging (5-50 characters)
    - Include a mix of short and medium words for good grid construction
    - Generate approximately {word_count} words (can be slightly more or less)

    IMPORTANT - Content Guidelines:
    - Use only publicly available factual information (general knowledge, public domain facts)
    - Do NOT reproduce copyrighted text, dialogue, lyrics, or specific plot details
    - For themed puzzles (Disney, Marvel, Star Wars, etc.), use only general public knowledge:
      * Character names (e.g., "The lion cub in The Lion King" → SIMBA)
      * General facts, not specific story details
      * Well-known catchphrases in a descriptive way, not direct quotes
    - Original clue wording only - do not copy copyrighted material
    - If theme involves trademarks, use descriptive clues referencing public knowledge only

    Return ONLY this JSON format (no additional text):
    {
      "title": "Puzzle Title",
      "description": "Brief description of the puzzle",
      "difficulty": "{requested_difficulty}",
      "words": [
        {"clue": "Clue text here", "answer": "ANSWER"}
      ]
    }
  PROMPT

  def initialize(api_key: nil)
    super()
    @api_key = api_key || ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key
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
      
      puts "=== CALLING GEMINI API ==="
      response = call_gemini_api(prompt)
      puts "Gemini response received"
      
      puts "=== PARSING AI RESPONSE ==="
      puzzle_data = parse_ai_response(response, request_params)
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
    # Get prompt template from environment variable or use default
    prompt_template = ENV['GEMINI_PROMPT_TEMPLATE'] || DEFAULT_PROMPT_TEMPLATE
    
    # Use theme if provided, otherwise use prompt as theme
    theme = params[:theme].present? ? params[:theme] : params[:prompt]
    
    prompt_template
      .gsub('{theme}', theme)
      .gsub('{requested_difficulty}', params[:difficulty])
      .gsub('{word_count}', params[:word_count].to_s)
  end

  def call_gemini_api(prompt)
    uri = URI("#{api_url}?key=#{@api_key}")
    
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
      generationConfig: GENERATION_CONFIG
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

    # Validate each word
    words = parsed['words'].map.with_index do |word, index|
      validate_word!(word, index)
      {
        clue: word['clue'].strip,
        answer: word['answer'].strip
      }
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

    # Validate answer format - uppercase letters only
    unless /^[A-Z]+$/.match?(word['answer'])
      raise ParseError, "Invalid word at index #{index}: answer must be UPPERCASE letters only (A-Z, no accented characters)"
    end

    unless (3..12).cover?(word['answer'].length)
      raise ParseError, "Invalid word at index #{index}: answer must be 3-12 letters long"
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

  def validate_and_trim_clues(clues)
    return clues if clues.empty?
    
    # Try to generate a crossword layout with all clues
    crossword_service = CrosswordGeneratorService.new
    layout_result = crossword_service.generate_layout(clues)
    
    # If all words fit, return the original clues
    if layout_result[:result].length == clues.length
      puts "All #{clues.length} clues fit in the crossword grid"
      return clues
    end
    
    # If not all words fit, try with fewer clues
    puts "Only #{layout_result[:result].length} out of #{clues.length} clues fit in the grid"
    puts "Attempting to trim clues to fit..."
    
    # Start with the words that successfully fit
    fitted_words = layout_result[:result].map { |word| 
      clues.find { |clue| clue['answer'] == word['answer'] }
    }.compact
    
    # If we have at least 3 words, use those
    if fitted_words.length >= 3
      puts "Using #{fitted_words.length} clues that fit in the grid"
      return fitted_words
    end
    
    # If we have fewer than 3 words, try progressively smaller sets
    (clues.length - 1).downto(3) do |count|
      subset = clues.first(count)
      layout_result = crossword_service.generate_layout(subset)
      
      if layout_result[:result].length == count
        puts "Successfully fitted #{count} clues in the grid"
        return subset
      end
    end
    
    # If all else fails, return the first 3 clues (they should fit)
    puts "Falling back to first 3 clues"
    clues.first(3)
  end
end
