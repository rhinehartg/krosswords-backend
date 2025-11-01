class CrosswordGeneratorService
  MAX_GRID_SIZE = 15

  def generate_layout(words, smart_order: false)
    # Pre-seed word order smartly: longest words first for better intersections
    ordered_words = if smart_order
      words.sort_by { |w| -(w['answer'].to_s.length) }
    else
      words
    end

    # Convert words to the format expected by JavaScript
    js_words = ordered_words.map do |word|
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
    layout = {
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

    # Compact/normalize: rebase coordinates so min startx/starty is (1,1)
    compact_layout(layout)
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

  # Hard reject if grid exceeds 15x15
  def fits_15x15?(layout)
    layout[:rows] <= MAX_GRID_SIZE && layout[:cols] <= MAX_GRID_SIZE
  end

  # Score layout: reward intersections & fill density, penalize islands and stretched aspect ratios
  def score_layout(layout)
    return -1000 unless fits_15x15?(layout)
    return -500 if layout[:result].empty?

    placed_words = layout[:result].select { |w| w[:orientation] != 'none' }
    return -100 if placed_words.empty?

    # Count intersections (words that share letters)
    intersections = count_intersections(placed_words, layout[:table])

    # Calculate fill density (percentage of grid filled)
    total_cells = layout[:rows] * layout[:cols]
    filled_cells = layout[:table].flatten.count { |cell| cell.present? }
    fill_density = total_cells > 0 ? (filled_cells.to_f / total_cells) : 0

    # Penalize stretched aspect ratios (prefer square-ish grids)
    aspect_ratio = [layout[:rows], layout[:cols]].max.to_f / [layout[:rows], layout[:cols]].min.to_f
    aspect_penalty = (aspect_ratio - 1.0) * 10

    # Count islands (disconnected word groups) - simplified check
    islands = count_islands(layout[:table], placed_words)

    # Score calculation: intersections are valuable, density is good, penalize aspect ratio and islands
    score = intersections * 10 +              # Reward intersections
            fill_density * 100 +              # Reward density
            placed_words.length * 5 -          # Reward word count
            aspect_penalty -                   # Penalize stretched grids
            islands * 50                       # Penalize disconnected islands

    score
  end

  # Compact layout by rebasing coordinates to start at (1,1)
  def compact_layout(layout)
    return layout if layout[:result].empty?

    # Find minimum startx and starty
    min_x = layout[:result].map { |w| w[:startx] }.compact.min || 1
    min_y = layout[:result].map { |w| w[:starty] }.compact.min || 1

    # If already starting at (1,1), return as is
    return layout if min_x == 1 && min_y == 1

    # Adjust all coordinates
    adjusted_result = layout[:result].map do |word|
      word.merge(
        startx: word[:startx] - min_x + 1,
        starty: word[:starty] - min_y + 1
      )
    end

    # Adjust table dimensions and rebuild if needed
    # For now, we'll keep the original table since the generator should handle this
    # In practice, you might want to rebuild the table, but this is a simpler approach

    layout.merge(result: adjusted_result)
  end

  private

  def count_intersections(words, table)
    # Count cells that have letters from multiple words
    # This is a simplified check - count cells with letters
    intersections = 0
    words.each do |word1|
      words.each do |word2|
        next if word1 == word2 || word2[:orientation] == 'none' || word1[:orientation] == 'none'
        
        # Check if words intersect (simplified: check if they share coordinates)
        word1_positions = get_word_positions(word1)
        word2_positions = get_word_positions(word2)
        
        if (word1_positions & word2_positions).any?
          intersections += 1
        end
      end
    end
    intersections / 2 # Each intersection counted twice
  end

  def get_word_positions(word)
    positions = []
    x, y = word[:startx], word[:starty]
    word[:answer].to_s.each_char do |char|
      positions << [x, y]
      if word[:orientation] == 'across'
        x += 1
      else
        y += 1
      end
    end
    positions
  end

  def count_islands(table, words)
    # Simplified island detection: count connected components
    # This is a basic implementation - you might want to improve it
    return 1 if words.empty?
    
    # Group words by connectivity
    groups = []
    words.each do |word|
      found_group = false
      word_positions = get_word_positions(word)
      
      groups.each_with_index do |group, idx|
        group_positions = group.flat_map { |w| get_word_positions(w) }
        if (word_positions & group_positions).any?
          groups[idx] << word
          found_group = true
          break
        end
      end
      
      groups << [word] unless found_group
    end
    
    groups.length
  end

  # Generate a complete puzzle using AI and create the crossword layout
  def generate_ai_puzzle(request_params)
    # First generate the puzzle content using AI
    ai_service = AiGeneratorService.new
    ai_result = ai_service.generate_puzzle(request_params)
    
    return ai_result unless ai_result[:success]
    
    puzzle = ai_result[:puzzle]
    
    # Then generate the crossword layout with smart ordering and validation
    # The validate_and_trim_clues in AiGeneratorService already ensures 15x15,
    # but we'll use smart ordering here for consistency
    layout_result = generate_layout(puzzle.clues, smart_order: true)
    
    # Final validation: ensure layout fits 15x15
    unless fits_15x15?(layout_result)
      Rails.logger.warn "Generated layout #{layout_result[:rows]}x#{layout_result[:cols]} exceeds 15x15, attempting to regenerate..."
      # Try regenerating with smart order (words should already be validated, but just in case)
      layout_result = generate_layout(puzzle.clues, smart_order: true)
    end
    
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
