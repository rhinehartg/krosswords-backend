require 'net/http'
require 'uri'
require 'json'

# Service for interactive template filling - handles one slot at a time
# Allows backtracking and constraint-aware word generation
class TemplateInteractiveFiller
  class Error < StandardError; end
  class ApiError < Error; end
  class ParseError < Error; end

  def initialize(api_key: nil)
    @api_key = api_key || ENV['GEMINI_API_KEY'] || (defined?(Rails) && Rails.application.credentials.dig(:gemini_api_key))
    @api_url = ENV['GEMINI_API_URL'] || 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent'
    raise Error, "Missing Gemini API key" if @api_key.blank?
  end

  # Generate word for a specific slot with constraints
  # @param template [Hash] Template structure
  # @param slot [Hash] The slot to fill
  # @param filled_slots [Array] Already filled slots with their words
  # @param theme [String] Theme for generation
  # @param difficulty [String] Difficulty level
  # @param hint [String, nil] Optional hint/clue preference
  def generate_word_for_slot(template, slot, filled_slots, theme: 'General', difficulty: 'Medium', hint: nil)
    # Calculate constraints from intersections
    constraints = calculate_constraints(slot, filled_slots, template)
    
    # Build prompt with constraints
    prompt = build_constraint_prompt(slot, constraints, filled_slots, theme, difficulty, hint)
    
    # Call Gemini
    response_text = call_gemini_api(prompt)
    
    # Parse and validate
    parse_word_response(response_text, slot, constraints)
  end

  # Calculate what letters are already fixed by intersecting words
  # Made public so Active Admin can use it
  def calculate_constraints(slot, filled_slots, template)
    constraints = {} # { position_in_slot => required_letter }
    
    return constraints if filled_slots.empty?
    
    # Get slot position
    startx = slot[:startx] - 1 # Convert to 0-based
    starty = slot[:starty] - 1
    
    if slot[:orientation] == 'across'
      # Check for intersecting down words
      slot[:length].times do |i|
        col = startx + i
        row = starty
        
        # Find any down words that intersect at this position
        filled_slots.each do |filled|
          next unless filled[:slot][:orientation] == 'down'
          
          fs_startx = filled[:slot][:startx] - 1
          fs_starty = filled[:slot][:starty] - 1
          fs_word = filled[:word][:answer]
          
          # Check if this down word crosses our across word
          if fs_startx == col && row >= fs_starty && row < fs_starty + fs_word.length
            position_in_down = row - fs_starty
            required_letter = fs_word[position_in_down]
            if required_letter
              constraints[i] = required_letter
            end
          end
        end
      end
    else # down
      # Check for intersecting across words
      slot[:length].times do |i|
        row = starty + i
        col = startx
        
        # Find any across words that intersect at this position
        filled_slots.each do |filled|
          next unless filled[:slot][:orientation] == 'across'
          
          fs_startx = filled[:slot][:startx] - 1
          fs_starty = filled[:slot][:starty] - 1
          fs_word = filled[:word][:answer]
          
          # Check if this across word crosses our down word
          if fs_starty == row && col >= fs_startx && col < fs_startx + fs_word.length
            position_in_across = col - fs_startx
            required_letter = fs_word[position_in_across]
            if required_letter
              constraints[i] = required_letter
            end
          end
        end
      end
    end
    
    constraints
  end

  private

  def build_constraint_prompt(slot, constraints, filled_slots, theme, difficulty, hint)
    constraint_desc = if constraints.any?
      "This word has #{constraints.length} fixed letter(s) from intersecting words:\n" +
      constraints.map { |pos, letter| "  - Position #{pos + 1}: must be '#{letter}'" }.join("\n")
    else
      "This word has no intersecting constraints (it's a starting word or edge word)."
    end

    existing_words = filled_slots.map { |fs| fs[:word][:answer] }.join(', ')
    existing_words_desc = existing_words.present? ? "Already used words: #{existing_words}" : "No words filled yet."

    hint_text = hint ? "Preferred clue direction: #{hint}" : ""

    prompt = <<~PROMPT
      Generate a crossword puzzle word with specific constraints.
      
      Theme: #{theme}
      Difficulty: #{difficulty}
      
      Required word:
      - Length: exactly #{slot[:length]} letters
      - Orientation: #{slot[:orientation]}
      #{constraint_desc}
      
      #{existing_words_desc}
      
      #{hint_text}
      
      Important constraints:
      - Answer must be UPPERCASE A-Z only, no spaces or special characters
      - Answer must be exactly #{slot[:length]} letters
      - If constraints specify fixed letters, the word MUST match them exactly
      - The word should relate to the theme: #{theme}
      - Clue should be concise (5-50 characters) and appropriate for #{difficulty} difficulty
      - Avoid repeating words that are already used: #{existing_words}
      
      Return ONLY this JSON format (no extra text):
      {
        "clue": "Clue text here",
        "answer": "ANSWER"
      }
      
      The answer must match the length and constraint requirements exactly.
    PROMPT

    prompt
  end

  def call_gemini_api(prompt)
    uri = URI("#{@api_url}?key=#{@api_key}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if defined?(Rails) && Rails.env.development?
    http.read_timeout = 30
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    request_body = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        temperature: 0.7, # Slightly higher for more variety when constraints allow
        maxOutputTokens: 1024,
        responseMimeType: "application/json"
      }
    }
    
    request.body = request_body.to_json
    
    Rails.logger.debug "Template Interactive Filler: Calling Gemini API" if defined?(Rails)
    response = http.request(request)
    
    unless response.code == '200'
      raise ApiError, "Gemini API request failed with status #{response.code}: #{response.body}"
    end
    
    parsed_response = JSON.parse(response.body)
    
    unless parsed_response["candidates"]&.any?
      raise ApiError, "No candidates found in AI response"
    end

    text = parsed_response.dig("candidates", 0, "content", "parts", 0, "text")
    text.to_s.strip
  rescue JSON::ParserError => e
    raise ApiError, "Failed to parse Gemini response: #{e.message}"
  end

  def parse_word_response(response_text, slot, constraints)
    # Clean the response text
    cleaned_text = response_text
      .gsub(/```json\n?/, '')
      .gsub(/```\n?/, '')
      .strip

    # Find JSON object in the response
    json_match = cleaned_text.match(/\{[\s\S]*\}/)
    unless json_match
      raise ParseError, 'No valid JSON found in AI response'
    end

    parsed = JSON.parse(json_match[0])
    
    unless parsed['answer'].present? && parsed['clue'].present?
      raise ParseError, 'Invalid response structure: missing answer or clue'
    end

    answer = parsed['answer'].strip.upcase
    
    # Validate format
    unless /^[A-Z]+$/.match?(answer)
      raise ParseError, "Answer must be letters only: #{answer}"
    end

    unless answer.length == slot[:length]
      raise ParseError, "Answer length mismatch: need #{slot[:length]}, got #{answer.length} (#{answer})"
    end

    # Validate constraints
    constraints.each do |position, required_letter|
      if answer[position] != required_letter
        raise ParseError, "Constraint violation: position #{position + 1} must be '#{required_letter}', got '#{answer[position]}'"
      end
    end

    {
      answer: answer,
      clue: parsed['clue'].strip,
      length: answer.length
    }
  end
end

