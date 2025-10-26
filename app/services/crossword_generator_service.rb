class CrosswordGeneratorService
  def generate_layout(words)
    # Convert words to the format expected by JavaScript
    js_words = words.map do |word|
      {
        'clue' => word['clue'],
        'answer' => word['answer']
      }
    end

    # Call Node.js script with the actual crossword-layout-generator package
    node_script_path = Rails.root.join('lib', 'crossword-generator-node.js')
    words_json = js_words.to_json
    
    # Execute Node.js script using base64 encoding to avoid shell issues
    encoded_json = Base64.encode64(words_json).strip
    result_json = `node "#{node_script_path}" "#{encoded_json}"`
    result = JSON.parse(result_json)
    
    # Convert result to Ruby hash
    {
      rows: result['rows'],
      cols: result['cols'],
      table: result['table'],
      result: result['result'].map do |word|
        {
          clue: word['clue'],
          answer: word['answer'],
          startx: word['startx'],
          starty: word['starty'],
          position: word['position'],
          orientation: word['orientation']
        }
      end
    }
  rescue => e
    Rails.logger.error "Crossword generation failed: #{e.message}"
    # Return a fallback layout
    {
      rows: 10,
      cols: 10,
      table: Array.new(10) { Array.new(10, '') },
      result: []
    }
  end

  # Generate a complete puzzle using AI and create the crossword layout
  def generate_ai_puzzle(request_params)
    # First generate the puzzle content using AI
    ai_service = AiGeneratorService.new
    ai_result = ai_service.generate_puzzle(request_params)
    
    return ai_result unless ai_result[:success]
    
    puzzle = ai_result[:puzzle]
    
    # Then generate the crossword layout
    layout_result = generate_layout(puzzle.clues)
    
    {
      success: true,
      puzzle: puzzle,
      layout: layout_result,
      error: nil
    }
  rescue StandardError => e
    Rails.logger.error "AI Puzzle generation failed: #{e.message}"
    {
      success: false,
      puzzle: nil,
      layout: nil,
      error: e.message
    }
  end
end
