# frozen_string_literal: true

# Interactive template filling - step by step with backtracking
ActiveAdmin.register_page "Interactive Template Fill" do
  menu false

  content do
    template_key = params[:template_key] || params[:id]
    theme = params[:theme] || "General"
    difficulty = params[:difficulty] || "Medium"
    
    if template_key.blank?
      div class: "flash flash_error" do
        span "Template key is required. Please select a template from the Generate AI Puzzle modal."
      end
      div style: "margin-top: 20px;" do
        link_to "Back to Puzzles", "/admin/puzzles", class: "button"
      end
      return
    end
    
    begin
      # Read template directly from ENV
      templates_json = ENV['CROSSWORD_TEMPLATES']
      raise "CROSSWORD_TEMPLATES environment variable not set" if templates_json.blank?
      
      templates_data = JSON.parse(templates_json)
      
      # Find the template
      template_data = if templates_data.is_a?(Hash)
        templates_data[template_key] || templates_data[template_key.to_sym]
      elsif templates_data.is_a?(Array)
        templates_data.find do |t|
          t.is_a?(Hash) && (
            t['key'] == template_key ||
            t[:key] == template_key ||
            t['name'] == template_key ||
            t[:name] == template_key
          )
        end
      end
      
      raise "Template '#{template_key}' not found" if template_data.nil?
      
      # Parse template using controller helper
      template = controller.parse_template_data(template_data, template_key)
      
      # Initialize filler
      begin
        filler = TemplateInteractiveFiller.new
      rescue => e
        div class: "flash flash_error" do
          span "TemplateInteractiveFiller error: #{e.message}"
        end
        div style: "margin-top: 20px;" do
          link_to "Back to Puzzles", "/admin/puzzles", class: "button"
        end
        return
      end
      
      # Get current state from session or params
      filled_slots_data = if params[:filled_slots].present?
        begin
          JSON.parse(params[:filled_slots])
        rescue JSON::ParserError
          []
        end
      else
        []
      end
      
      current_slot_index = params[:current_slot] ? params[:current_slot].to_i : 0
      
      filled_slots = filled_slots_data.map do |data|
        slot_idx = data['slot_index'].to_i
        {
          slot: template[:word_slots][slot_idx],
          word: { answer: data['answer'], clue: data['clue'] },
          slot_index: slot_idx
        }
      end
      
      if current_slot_index >= template[:word_slots].length
        # All slots filled - show completion
        controller.render_completed_puzzle(self, template, filled_slots, theme, difficulty)
      else
        current_slot = template[:word_slots][current_slot_index]
        
        # Show current state and form for next slot
        controller.render_filling_interface(self, template, current_slot, current_slot_index, filled_slots, theme, difficulty, filler)
      end
    rescue => e
      div class: "flash flash_error" do
        h3 "Error loading template"
        p e.message
        pre style: "font-size: 12px; margin-top: 10px; padding: 10px; background: #f8f8f8; border-radius: 4px; overflow-x: auto;" do
          e.backtrace.first(5).join("\n")
        end
      end
      div style: "margin-top: 20px;" do
        link_to "Back to Puzzles", "/admin/puzzles", class: "button"
      end
    end
  end

  page_action :generate_word, method: :post do
    template_key = params[:template_key] || params[:id]
    slot_index = params[:slot_index].to_i
    theme = params[:theme]
    difficulty = params[:difficulty]
    filled_slots_json = params[:filled_slots]
    hint = params[:hint]
    
    begin
      # Read template
      templates_json = ENV['CROSSWORD_TEMPLATES']
      raise "CROSSWORD_TEMPLATES not set" if templates_json.blank?
      
      templates_data = JSON.parse(templates_json)
      template_data = if templates_data.is_a?(Hash)
        templates_data[template_key]
      elsif templates_data.is_a?(Array)
        templates_data.find { |t| (t['key'] || t['name']) == template_key }
      end
      
      template = controller.parse_template_data(template_data, template_key)
      
      filler = TemplateInteractiveFiller.new
      
      filled_slots_data = filled_slots_json.present? ? JSON.parse(filled_slots_json) : []
      filled_slots = filled_slots_data.map do |data|
        {
          slot: template[:word_slots][data['slot_index']],
          word: { answer: data['answer'], clue: data['clue'] },
          slot_index: data['slot_index']
        }
      end
      
      current_slot = template[:word_slots][slot_index]
      
      # Generate word with constraints
      word_result = filler.generate_word_for_slot(
        template,
        current_slot,
        filled_slots,
        theme: theme,
        difficulty: difficulty,
        hint: hint
      )
      
      # Add to filled slots
      filled_slots_data << {
        'slot_index' => slot_index,
        'answer' => word_result[:answer],
        'clue' => word_result[:clue]
      }
      
      # Move to next slot
      next_slot_index = slot_index + 1
      
      redirect_to "/admin/interactive_template_fill?template_key=#{CGI.escape(template_key)}&theme=#{CGI.escape(theme)}&difficulty=#{CGI.escape(difficulty)}&current_slot=#{next_slot_index}&filled_slots=#{CGI.escape(filled_slots_data.to_json)}"
    rescue => e
      redirect_to "/admin/interactive_template_fill?template_key=#{CGI.escape(template_key)}&theme=#{CGI.escape(theme)}&difficulty=#{CGI.escape(difficulty)}&current_slot=#{slot_index}&filled_slots=#{CGI.escape(filled_slots_json)}&error=#{CGI.escape(e.message)}"
    end
  end

  page_action :backtrack, method: :post do
    template_key = params[:template_key] || params[:id]
    back_to_index = params[:back_to_index].to_i
    theme = params[:theme]
    difficulty = params[:difficulty]
    filled_slots_json = params[:filled_slots]
    
    filled_slots_data = filled_slots_json.present? ? JSON.parse(filled_slots_json) : []
    # Remove all slots after the target index
    filled_slots_data = filled_slots_data.select { |data| data['slot_index'] < back_to_index }
    
    redirect_to "/admin/interactive_template_fill?template_key=#{CGI.escape(template_key)}&theme=#{CGI.escape(theme)}&difficulty=#{CGI.escape(difficulty)}&current_slot=#{back_to_index}&filled_slots=#{CGI.escape(filled_slots_data.to_json)}"
  end

  controller do
    # Skip CSRF for page actions - Active Admin already handles authentication
    skip_before_action :verify_authenticity_token, only: [:generate_word, :backtrack], raise: false
    
    # Helper methods for template parsing and rendering
    def parse_template_data(data, template_key)
      # Normalize hash keys
      data = normalize_hash_keys(data) if data.is_a?(Hash)
      
      rows = data['rows'] || 15
      cols = data['cols'] || 15
      
      # Parse grid structure
      grid = parse_grid_structure(data['grid'], rows, cols)
      
      # Auto-detect word slots
      word_slots = if data['word_slots'].present?
        parse_word_slots(data['word_slots'])
      else
        detect_word_slots_from_grid(grid, rows, cols)
      end
      
      {
        name: data['name'] || template_key.to_s,
        key: template_key.to_s,
        rows: rows,
        cols: cols,
        grid: grid,
        word_slots: word_slots,
        theme: data['theme'],
        difficulty: data['difficulty'] || 'Medium'
      }
    end

    def normalize_hash_keys(data)
      case data
      when Hash
        normalized = {}
        data.each { |k, v| normalized[k.to_s] = normalize_hash_keys(v) }
        normalized
      when Array
        data.map { |item| normalize_hash_keys(item) }
      else
        data
      end
    end

    def parse_grid_structure(grid_data, rows, cols)
      return nil if grid_data.blank?
      
      if grid_data.is_a?(Array) && grid_data.first.is_a?(Array)
        return grid_data.map { |row| row.map { |cell| normalize_cell(cell) } }
      end
      
      if grid_data.is_a?(Array) && grid_data.length == rows * cols
        grid = []
        rows.times do |r|
          row = []
          cols.times do |c|
            row << normalize_cell(grid_data[r * cols + c])
          end
          grid << row
        end
        return grid
      end
      
      if grid_data.is_a?(String)
        grid = []
        lines = grid_data.split("\n").reject(&:blank?)
        rows.times do |r|
          line = lines[r] || ''
          row = []
          cols.times do |c|
            char = line[c] || '.'
            row << normalize_cell(char)
          end
          grid << row
        end
        return grid
      end
      
      Array.new(rows) { Array.new(cols, false) }
    end

    def normalize_cell(cell)
      case cell.to_s.downcase
      when '#', 'black', 'blocked', 'x', '1', 'true'
        true
      else
        false
      end
    end

    def detect_word_slots_from_grid(grid, rows, cols)
      slots = []
      slot_id = 1
      
      # Across words
      rows.times do |row|
        word_start = nil
        word_length = 0
        
        cols.times do |col|
          is_black = grid && grid[row] && grid[row][col]
          
          if is_black
            if word_start && word_length >= 3
              slots << {
                id: slot_id,
                startx: word_start + 1,
                starty: row + 1,
                orientation: 'across',
                length: word_length
              }
              slot_id += 1
            end
            word_start = nil
            word_length = 0
          else
            word_start ||= col
            word_length += 1
          end
        end
        
        if word_start && word_length >= 3
          slots << {
            id: slot_id,
            startx: word_start + 1,
            starty: row + 1,
            orientation: 'across',
            length: word_length
          }
          slot_id += 1
        end
      end
      
      # Down words
      cols.times do |col|
        word_start = nil
        word_length = 0
        
        rows.times do |row|
          is_black = grid && grid[row] && grid[row][col]
          
          if is_black
            if word_start && word_length >= 3
              slots << {
                id: slot_id,
                startx: col + 1,
                starty: word_start + 1,
                orientation: 'down',
                length: word_length
              }
              slot_id += 1
            end
            word_start = nil
            word_length = 0
          else
            word_start ||= row
            word_length += 1
          end
        end
        
        if word_start && word_length >= 3
          slots << {
            id: slot_id,
            startx: col + 1,
            starty: word_start + 1,
            orientation: 'down',
            length: word_length
          }
          slot_id += 1
        end
      end
      
      slots
    end

    def parse_word_slots(slots_data)
      slots_data.map.with_index do |slot, index|
        {
          id: slot['id'] || (index + 1),
          startx: slot['startx'].to_i,
          starty: slot['starty'].to_i,
          orientation: normalize_orientation(slot['orientation']),
          length: slot['length'].to_i
        }
      end
    end

    def normalize_orientation(orientation)
      case orientation.to_s.downcase
      when 'across', 'horizontal', 'h', 'a'
        'across'
      when 'down', 'vertical', 'v', 'd'
        'down'
      else
        'across'
      end
    end

    # Render methods need access to the Arbre DSL context (the 'page' object)
    def render_filling_interface(page, template, current_slot, current_slot_index, filled_slots, theme, difficulty, filler)
      # Calculate constraints
      constraints = filler.calculate_constraints(current_slot, filled_slots, template)
      
      # Build current grid state
      grid_state = build_grid_state(template, filled_slots)
      
      page.instance_eval do
        div class: "interactive_fill" do
          h2 "Filling Template: #{template[:name]}"
          
          if params[:error]
            div class: "flash flash_error", style: "margin: 20px 0; padding: 15px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px;" do
              span "Error: #{params[:error]}"
            end
          end
          
          # Progress
          div style: "margin: 20px 0; padding: 15px; background: #e7f3ff; border-radius: 4px;" do
            h4 "Progress: #{filled_slots.length} / #{template[:word_slots].length} words filled"
            
            # Show filled words
            if filled_slots.any?
              h5 "Filled Words:"
              ul style: "margin-top: 10px;" do
                filled_slots.each do |filled|
                  slot = filled[:slot]
                  li do
                    strong "#{slot[:orientation].capitalize} #{slot[:id]}: " 
                    span "#{filled[:word][:answer]} - #{filled[:word][:clue]}"
                    form action: "/admin/interactive_template_fill/backtrack", method: :post, style: "display: inline; margin-left: 10px;" do
                      input type: "hidden", name: "template_key", value: template[:key]
                      input type: "hidden", name: "back_to_index", value: filled[:slot_index]
                      input type: "hidden", name: "theme", value: theme
                      input type: "hidden", name: "difficulty", value: difficulty
                      input type: "hidden", name: "filled_slots", value: filled_slots.map { |fs| { 'slot_index' => fs[:slot_index], 'answer' => fs[:word][:answer], 'clue' => fs[:word][:clue] } }.to_json
                      input type: "submit", value: "Re-fill from here", style: "padding: 4px 8px; font-size: 11px; background: #ffc107; border: none; border-radius: 3px; cursor: pointer;"
                    end
                  end
                end
              end
            end
          end
          
          # Current grid visualization
          div style: "margin: 20px 0;" do
            h4 "Current Grid State:"
            # Render grid inline to avoid nested instance_eval
            div style: "font-family: monospace; background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; display: inline-block;" do
              table style: "border-collapse: collapse; cellpadding: 0; cellspacing: 0;" do
                template[:rows].times do |row|
                  tr do
                    template[:cols].times do |col|
                      cell = grid_state[row][col]
                      is_current = current_slot[:orientation] == 'across' ? 
                        (row == current_slot[:starty] - 1 && col >= current_slot[:startx] - 1 && col < current_slot[:startx] - 1 + current_slot[:length]) :
                        (col == current_slot[:startx] - 1 && row >= current_slot[:starty] - 1 && row < current_slot[:starty] - 1 + current_slot[:length])
                      
                      is_constrained = if current_slot[:orientation] == 'across'
                        row == current_slot[:starty] - 1 && col >= current_slot[:startx] - 1 && col < current_slot[:startx] - 1 + current_slot[:length] && constraints.key?(col - (current_slot[:startx] - 1))
                      else
                        col == current_slot[:startx] - 1 && row >= current_slot[:starty] - 1 && row < current_slot[:starty] - 1 + current_slot[:length] && constraints.key?(row - (current_slot[:starty] - 1))
                      end
                      
                      bg_color = if cell == '#'
                        "#000"
                      elsif is_constrained
                        "#fff3cd"
                      elsif is_current
                        "#cfe2ff"
                      elsif cell.present?
                        "#fff"
                      else
                        "#f8f9fa"
                      end
                      
                      border_color = is_current ? "#007bff" : "#ddd"
                      
                      td style: "width: 25px; height: 25px; border: 1px solid #{border_color}; background: #{bg_color}; text-align: center; vertical-align: middle; font-weight: bold; font-size: 14px;" do
                        if cell == '#'
                          "█"
                        elsif is_constrained && cell.present?
                          span style: "color: #856404;" do cell end
                        elsif cell.present?
                          cell
                        elsif is_current
                          "·"
                        else
                          " "
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Current slot form
          div style: "margin: 20px 0; padding: 20px; border: 2px solid #007bff; border-radius: 8px; background: #f0f8ff;" do
            h3 "Fill Slot #{current_slot_index + 1}: #{current_slot[:orientation].capitalize} #{current_slot[:id]}"
            
            div style: "margin: 10px 0;" do
              p do
                strong "Length: " 
                span "#{current_slot[:length]} letters"
              end
              p do
                strong "Position: " 
                span "Row #{current_slot[:starty]}, Column #{current_slot[:startx]}"
              end
              
              if constraints.any?
                p style: "color: #d32f2f; font-weight: bold;" do
                  "Constraints (fixed letters from intersections):"
                end
                ul do
                  constraints.each do |position, letter|
                    li do
                      "Position #{position + 1}: must be '#{letter}'"
                    end
                  end
                end
              else
                p style: "color: #28a745;" do "No constraints - free word generation" end
              end
            end
            
            form action: "/admin/interactive_template_fill/generate_word", method: :post do
              input type: "hidden", name: "template_key", value: template[:key]
              input type: "hidden", name: "slot_index", value: current_slot_index
              input type: "hidden", name: "theme", value: theme
              input type: "hidden", name: "difficulty", value: difficulty
              input type: "hidden", name: "filled_slots", value: filled_slots.map { |fs| { 'slot_index' => fs[:slot_index], 'answer' => fs[:word][:answer], 'clue' => fs[:word][:clue] } }.to_json
              
              div style: "margin: 15px 0;" do
                label style: "display: block; margin-bottom: 5px; font-weight: bold;" do
                  "Clue Hint (optional):"
                end
                input type: "text", name: "hint", placeholder: "e.g., 'a type of fruit' or 'capital city'", style: "width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px;"
              end
              
              div style: "margin-top: 20px;" do
                input type: "submit", value: "Generate Word with AI", class: "button", style: "padding: 12px 24px; background: #007bff; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;"
                span " | "
                link_to "Cancel", "/admin/puzzles", class: "button"
              end
            end
          end
        end
      end
    end

    def render_completed_puzzle(page, template, filled_slots, theme, difficulty)
      # Build final grid
      grid = Array.new(template[:rows]) { Array.new(template[:cols], '') }
      
      # Mark black squares
      if template[:grid]
        template[:rows].times do |row|
          template[:cols].times do |col|
            if template[:grid][row] && template[:grid][row][col]
              grid[row][col] = '#'
            end
          end
        end
      end
      
      # Fill in words
      across_clues = []
      down_clues = []
      
      filled_slots.each do |filled|
        slot = filled[:slot]
        word = filled[:word][:answer]
        startx = slot[:startx] - 1
        starty = slot[:starty] - 1
        
        if slot[:orientation] == 'across'
          word.each_char.with_index do |char, i|
            col = startx + i
            grid[starty][col] = char if col < template[:cols] && starty < template[:rows] && grid[starty][col] != '#'
          end
          across_clues << { clue: filled[:word][:clue], answer: word, startx: slot[:startx], starty: slot[:starty] }
        else
          word.each_char.with_index do |char, i|
            row = starty + i
            grid[row][startx] = char if row < template[:rows] && startx < template[:cols] && grid[row][startx] != '#'
          end
          down_clues << { clue: filled[:word][:clue], answer: word, startx: slot[:startx], starty: slot[:starty] }
        end
      end
      
      page.instance_eval do
        div class: "completed_puzzle" do
          h2 "Puzzle Completed! 🎉"
          
          div style: "margin: 20px 0; padding: 15px; background: #d4edda; border: 1px solid #c3e6cb; border-radius: 4px;" do
            h3 "Final Grid:"
            # Render grid inline to avoid nested instance_eval
            div style: "font-family: monospace; background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto;" do
              grid.each do |row|
                div do
                  row.map { |cell| cell == '#' ? '█' : (cell.present? ? cell : '·') }.join(' ')
                end
              end
            end
          end
          
          div style: "margin: 20px 0;" do
            h3 "Clues - Across"
            ul do
              across_clues.each_with_index do |word, index|
                li do
                  strong "#{index + 1}. "
                  span word[:clue]
                  span " (#{word[:answer]})", style: "color: #666; font-size: 0.9em;"
                end
              end
            end
          end
          
          div style: "margin: 20px 0;" do
            h3 "Clues - Down"
            ul do
              down_clues.each_with_index do |word, index|
                li do
                  strong "#{index + 1}. "
                  span word[:clue]
                  span " (#{word[:answer]})", style: "color: #666; font-size: 0.9em;"
                end
              end
            end
          end
          
          div style: "margin-top: 20px;" do
            link_to "Back to Puzzles", "/admin/puzzles", class: "button"
          end
        end
      end
    end

    def build_grid_state(template, filled_slots)
      grid = Array.new(template[:rows]) { Array.new(template[:cols], '') }
      
      # Mark black squares
      if template[:grid]
        template[:rows].times do |row|
          template[:cols].times do |col|
            if template[:grid][row] && template[:grid][row][col]
              grid[row][col] = '#'
            end
          end
        end
      end
      
      # Fill in words
      filled_slots.each do |filled|
        slot = filled[:slot]
        word = filled[:word][:answer]
        startx = slot[:startx] - 1
        starty = slot[:starty] - 1
        
        if slot[:orientation] == 'across'
          word.each_char.with_index do |char, i|
            col = startx + i
            grid[starty][col] = char if col < template[:cols] && starty < template[:rows] && grid[starty][col] != '#'
          end
        else
          word.each_char.with_index do |char, i|
            row = starty + i
            grid[row][startx] = char if row < template[:rows] && startx < template[:cols] && grid[row][startx] != '#'
          end
        end
      end
      
      grid
    end

    # Removed render_grid and render_grid_preview - now inlined to avoid nested instance_eval issues
  end
end
