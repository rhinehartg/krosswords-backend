require 'json'

ActiveAdmin.register Puzzle do
  # Permit parameters for puzzle management
  permit_params :description, :is_published, :challenge_date, :game_type, :puzzle_data
  
  controller do
    # Parse puzzle_data string to hash before Active Admin processes params
    before_action :parse_puzzle_data_string, only: [:create, :update]
    
    # Override build_resource to set puzzle_data after building
    def build_resource
      resource = super
      
      # Manually set puzzle_data from params if present (bypasses strong params)
      if params[:puzzle] && params[:puzzle][:puzzle_data].present?
        puzzle_data = params[:puzzle][:puzzle_data]
        resource.puzzle_data = puzzle_data if puzzle_data.present?
      end
      
      resource
    end
    
    # Override update to manually set puzzle_data
    def update
      if params[:puzzle] && params[:puzzle][:puzzle_data].present?
        puzzle_data = params[:puzzle][:puzzle_data]
        resource.puzzle_data = puzzle_data
      end
      super
    end
    
    private
    
    def parse_puzzle_data_string
      if params[:puzzle] && params[:puzzle][:puzzle_data].present?
        puzzle_data_value = params[:puzzle][:puzzle_data]
        
        # Parse if it's a string
        if puzzle_data_value.is_a?(String)
          begin
            parsed = JSON.parse(puzzle_data_value)
            params[:puzzle][:puzzle_data] = parsed
          rescue JSON::ParserError => e
            # Will be caught by validation
          end
        end
      end
    end
    
    # Helper method to shuffle array with seed (matching JavaScript logic)
    def shuffle_with_seed(array, seed)
      # Create hash from seed (matching JavaScript hash function)
      hash = 0
      seed.each_byte do |byte|
        hash = ((hash << 5) - hash) + byte
        hash = hash & hash # Convert to 32bit integer
      end
      
      # Fisher-Yates shuffle with seeded random
      shuffled = array.dup
      seed_value = hash.abs
      
      (shuffled.length - 1).downto(1) do |i|
        # Generate pseudo-random index using seed (matching JavaScript PRNG)
        seed_value = (seed_value * 9301 + 49297) % 233280
        j = ((seed_value.to_f / 233280) * (i + 1)).floor
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
      end
      
      shuffled
    end
    
  end

  # Quick-create buttons for each game type
  action_item :quick_create_krossword, only: [:index] do
    link_to 'Quick Create Krossword', quick_create_krossword_admin_puzzles_path,
      style: 'background-color: #007bff !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #007bff !important; display: inline-block; cursor: pointer;'
  end
  
  action_item :quick_create_konundrum, only: [:index] do
    link_to 'Quick Create Konundrum', quick_create_konundrum_admin_puzzles_path,
      style: 'background-color: #28a745 !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #28a745 !important; display: inline-block; cursor: pointer;'
  end
  
  action_item :quick_create_krisskross, only: [:index] do
    link_to 'Quick Create KrissKross', quick_create_krisskross_admin_puzzles_path,
      style: 'background-color: #ff6b35 !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #ff6b35 !important; display: inline-block; cursor: pointer;'
  end
  
  action_item :quick_create_konstructor, only: [:index] do
    link_to 'Quick Create Konstructor', quick_create_konstructor_admin_puzzles_path,
      style: 'background-color: #9b59b6 !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #9b59b6 !important; display: inline-block; cursor: pointer;'
  end
  
  # Add quick edit buttons for each game type
  action_item :quick_edit, only: [:show, :edit] do
    case resource.game_type
    when 'krossword'
      link_to 'Quick Edit', quick_edit_krossword_admin_puzzle_path(resource),
        style: 'background-color: #007bff !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #007bff !important; display: inline-block; cursor: pointer;'
    when 'konundrum'
      link_to 'Quick Edit', quick_edit_konundrum_admin_puzzle_path(resource),
        style: 'background-color: #28a745 !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #28a745 !important; display: inline-block; cursor: pointer;'
    when 'krisskross'
      link_to 'Quick Edit', quick_edit_krisskross_admin_puzzle_path(resource),
        style: 'background-color: #ff6b35 !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #ff6b35 !important; display: inline-block; cursor: pointer;'
    when 'konstructor'
      link_to 'Quick Edit', quick_edit_konstructor_admin_puzzle_path(resource),
        style: 'background-color: #9b59b6 !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #9b59b6 !important; display: inline-block; cursor: pointer;'
    end
  end
  
  # Add preview and regenerate buttons for Konundrum puzzles
  action_item :preview_konundrum, only: [:show, :edit] do
    if resource.game_type == 'konundrum' && resource.puzzle_data.present? && resource.puzzle_data['words'].present?
      link_to 'Preview Konundrum', preview_konundrum_admin_puzzle_path(resource),
        target: '_blank',
        style: 'background-color: #28a745 !important; color: black !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #28a745 !important; display: inline-block; cursor: pointer;'
    end
  end
  
  action_item :regenerate_letters, only: [:show, :edit] do
    if resource.game_type == 'konundrum' && resource.puzzle_data.present? && resource.puzzle_data['words'].present?
      link_to 'Regenerate Letters', regenerate_letters_admin_puzzle_path(resource),
        method: :post,
        data: { confirm: 'This will generate a new random shuffle of the letters. Continue?' },
        style: 'background-color: #e0e7ff !important; color: #1e3a8a !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #667eea !important; display: inline-block; cursor: pointer;'
    end
  end
  
  # Collection actions for quick-create forms
  collection_action :quick_create_krossword, method: [:get, :post] do
    if request.post?
      puzzle_clue = params[:puzzle_clue] || ''
      clues_text = params[:clues] || ''
      generate_layout = params[:generate_layout] == '1'
      
      if puzzle_clue.blank?
        flash[:error] = 'Please provide a puzzle clue'
        redirect_to quick_create_krossword_admin_puzzles_path and return
      end
      
      # Parse clues from text (format: "Clue text | ANSWER")
      clues = []
      clues_text.split("\n").each do |line|
        line = line.strip
        next if line.blank?
        
        if line.include?('|')
          parts = line.split('|', 2)
          clue_text = parts[0].strip
          answer = parts[1].strip.upcase
          clues << { 'clue' => clue_text, 'answer' => answer } if clue_text.present? && answer.present?
        else
          # Try to parse as just answer (no clue)
          answer = line.upcase
          clues << { 'clue' => '', 'answer' => answer } if answer.present?
        end
      end
      
      if clues.empty?
        flash[:error] = 'Please provide at least one clue (format: "Clue text | ANSWER")'
        redirect_to quick_create_krossword_admin_puzzles_path and return
      end
      
      # Build puzzle_data
      puzzle_data = {
        'puzzle_clue' => puzzle_clue,
        'clues' => clues
      }
      
      # Optionally generate layout
      if generate_layout
        begin
          crossword_service = CrosswordGeneratorService.new
          layout = crossword_service.generate_layout(clues, smart_order: true)
          puzzle_data['layout'] = {
            'rows' => layout[:rows],
            'cols' => layout[:cols],
            'table' => layout[:table],
            'result' => layout[:result].map do |word|
              {
                'clue' => word[:clue] || word['clue'] || '',
                'answer' => word[:answer] || word['answer'] || '',
                'startx' => word[:startx] || word['startx'] || 1,
                'starty' => word[:starty] || word['starty'] || 1,
                'position' => word[:position] || word['position'] || 1,
                'orientation' => (word[:orientation] || word['orientation'] || 'across').to_s
              }
            end
          }
        rescue => e
          Rails.logger.error "Error generating layout: #{e.message}"
          # Continue without layout - it's optional
        end
      end
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_create_krossword_admin_puzzles_path and return
        end
      end
      
      # Create puzzle
      puzzle = Puzzle.new(
        game_type: 'krossword',
        is_published: params[:is_published] == '1',
        challenge_date: challenge_date,
        puzzle_data: puzzle_data
      )
      
      if puzzle.save
        redirect_to admin_puzzle_path(puzzle), notice: 'Krossword puzzle created successfully!'
      else
        flash[:error] = "Error: #{puzzle.errors.full_messages.join(', ')}"
        redirect_to quick_create_krossword_admin_puzzles_path
      end
    else
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Create Krossword Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_create_krossword_admin_puzzles_path %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Puzzle Clue/Theme (required):</label>
              <input type="text" name="puzzle_clue" placeholder="e.g., Nature and Wildlife" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Clues (one per line, format: 'Clue text | ANSWER'):</label>
              <textarea name="clues" rows="10" placeholder="A body of water | OCEAN&#10;Large cat | TIGER&#10;Bright light | LIGHT" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"></textarea>
              <small style="color: #666;">Enter clues one per line. Format: 'Clue text | ANSWER' (use pipe to separate clue from answer)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="generate_layout" value="1" />
                Generate crossword layout automatically
              </label>
              <small style="color: #666;"> (Optional - layout can be generated later)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge (Krossword puzzles must be on Sunday)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Create Puzzle</button>
              <a href="<%= admin_puzzles_path %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  collection_action :quick_create_konundrum, method: [:get, :post] do
    if request.post?
      clue = params[:clue] || ''
      words_text = params[:words] || ''
      words = words_text.split("\n").map(&:strip).reject(&:blank?).map(&:upcase)
      
      if words.empty?
        flash[:error] = 'Please provide at least one word'
        redirect_to quick_create_konundrum_admin_puzzles_path and return
      end
      
      # Generate seed (use provided or auto-generate)
      seed = params[:seed].present? ? params[:seed] : "konundrum-#{Time.now.to_i * 1000 + rand(1000)}-#{words.join('-')}"
      
      # Shuffle letters (matching JavaScript logic)
      all_letters = words.join('').split('').select { |l| l.match?(/[A-Z]/) }
      shuffled_letters = shuffle_with_seed(all_letters, seed)
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_create_konundrum_admin_puzzles_path and return
        end
      end
      
      # Create puzzle
      puzzle_data_hash = {
        'words' => words,
        'letters' => shuffled_letters,
        'seed' => seed
      }
      # Add clue only if provided (optional - blank means "clueless" mode)
      puzzle_data_hash['clue'] = clue if clue.present?
      
      puzzle = Puzzle.new(
        game_type: 'konundrum',
        is_published: params[:is_published] == '1',
        challenge_date: challenge_date,
        puzzle_data: puzzle_data_hash
      )
      
      if puzzle.save
        redirect_to admin_puzzle_path(puzzle), notice: 'Konundrum puzzle created successfully!'
      else
        flash[:error] = "Error: #{puzzle.errors.full_messages.join(', ')}"
        redirect_to quick_create_konundrum_admin_puzzles_path
      end
    else
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Create Konundrum Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_create_konundrum_admin_puzzles_path %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Clue/Theme (optional):</label>
              <input type="text" name="clue" placeholder="e.g., Ocean Life, or leave blank for 'clueless'" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Leave blank for extra difficulty (clueless mode)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Words (one per line):</label>
              <textarea name="words" rows="5" placeholder="OCEAN&#10;TIGER&#10;LIGHT" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"></textarea>
              <small style="color: #666;">Enter words one per line. Letters will be automatically shuffled.</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Seed (optional - auto-generated if blank):</label>
              <input type="text" name="seed" placeholder="Auto-generated from words and timestamp" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;" />
              <small style="color: #666;">Seed controls letter randomization. Leave blank to auto-generate, or set manually for reproducible shuffling.</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #28a745; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Create Puzzle</button>
              <a href="<%= admin_puzzles_path %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  collection_action :quick_create_krisskross, method: [:get, :post] do
    if request.post?
      clue = params[:clue] || ''
      words_text = params[:words] || ''
      words = words_text.split("\n").map(&:strip).reject(&:blank?).map(&:upcase)
      
      if words.length < 2
        flash[:error] = 'Please provide at least 2 words (one per line)'
        redirect_to quick_create_krisskross_admin_puzzles_path and return
      end
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_create_krisskross_admin_puzzles_path and return
        end
      end
      
      # Generate layout using CrosswordGeneratorService
      begin
        crossword_service = CrosswordGeneratorService.new
        words_with_clues = words.map { |w| { 'clue' => '', 'answer' => w } }
        layout = crossword_service.generate_layout(words_with_clues, smart_order: true)
        
        # Create puzzle
        puzzle_data_hash = {
          words: words,
          layout: {
            rows: layout[:rows],
            cols: layout[:cols],
            table: layout[:table],
            result: layout[:result]
          }
        }
        
        # Only include clue if it's provided
        puzzle_data_hash[:clue] = clue if clue.present?
        
        puzzle = Puzzle.new(
          game_type: 'krisskross',
          is_published: params[:is_published] == '1',
          challenge_date: challenge_date,
          puzzle_data: puzzle_data_hash
        )
        
        if puzzle.save
          redirect_to admin_puzzle_path(puzzle), notice: 'KrissKross puzzle created successfully!'
        else
          flash[:error] = "Error: #{puzzle.errors.full_messages.join(', ')}"
          redirect_to quick_create_krisskross_admin_puzzles_path
        end
      rescue => e
        flash[:error] = "Error generating layout: #{e.message}"
        redirect_to quick_create_krisskross_admin_puzzles_path
      end
    else
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Create KrissKross Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_create_krisskross_admin_puzzles_path %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Clue/Theme (optional):</label>
              <input type="text" name="clue" placeholder="e.g., Ocean, Animals, Food" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Words (one per line, at least 2):</label>
              <textarea name="words" rows="5" placeholder="WATER&#10;WAVE&#10;CORAL" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"></textarea>
              <small style="color: #666;">Enter at least 2 words. Layout will be automatically generated.</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #ff6b35; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Create Puzzle</button>
              <a href="<%= admin_puzzles_path %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  collection_action :quick_create_konstructor, method: [:get, :post] do
    if request.post?
      puzzle_clue = params[:puzzle_clue] || ''
      words_text = params[:words] || ''
      words = words_text.split("\n").map(&:strip).reject(&:blank?).map(&:upcase)
      
      if words.empty?
        flash[:error] = 'Please provide at least one word'
        redirect_to quick_create_konstructor_admin_puzzles_path and return
      end
      
      if puzzle_clue.blank?
        flash[:error] = 'Please provide a puzzle clue'
        redirect_to quick_create_konstructor_admin_puzzles_path and return
      end
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_create_konstructor_admin_puzzles_path and return
        end
      end
      
      # Create puzzle
      puzzle = Puzzle.new(
        game_type: 'konstructor',
        is_published: params[:is_published] == '1',
        challenge_date: challenge_date,
        puzzle_data: {
          puzzle_clue: puzzle_clue,
          words: words
        }
      )
      
      if puzzle.save
        redirect_to admin_puzzle_path(puzzle), notice: 'Konstructor puzzle created successfully!'
      else
        flash[:error] = "Error: #{puzzle.errors.full_messages.join(', ')}"
        redirect_to quick_create_konstructor_admin_puzzles_path
      end
    else
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Create Konstructor Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_create_konstructor_admin_puzzles_path %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Puzzle Clue/Theme (required):</label>
              <input type="text" name="puzzle_clue" placeholder="e.g., Mother Nature's domain" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Words (one per line):</label>
              <textarea name="words" rows="10" placeholder="OCEAN&#10;TREE&#10;SUN&#10;MOUNTAIN&#10;FOREST" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"></textarea>
              <small style="color: #666;">Enter words one per line. Players will place these on a grid.</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #9b59b6; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Create Puzzle</button>
              <a href="<%= admin_puzzles_path %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  # Member actions for quick editing (reusing the same forms)
  member_action :quick_edit_krossword, method: [:get, :post] do
    if request.post?
      puzzle_clue = params[:puzzle_clue] || ''
      clues_text = params[:clues] || ''
      generate_layout = params[:generate_layout] == '1'
      
      if puzzle_clue.blank?
        flash[:error] = 'Please provide a puzzle clue'
        redirect_to quick_edit_krossword_admin_puzzle_path(resource) and return
      end
      
      # Parse clues from text (format: "Clue text | ANSWER")
      clues = []
      clues_text.split("\n").each do |line|
        line = line.strip
        next if line.blank?
        
        if line.include?('|')
          parts = line.split('|', 2)
          clue_text = parts[0].strip
          answer = parts[1].strip.upcase
          clues << { 'clue' => clue_text, 'answer' => answer } if clue_text.present? && answer.present?
        else
          answer = line.upcase
          clues << { 'clue' => '', 'answer' => answer } if answer.present?
        end
      end
      
      if clues.empty?
        flash[:error] = 'Please provide at least one clue (format: "Clue text | ANSWER")'
        redirect_to quick_edit_krossword_admin_puzzle_path(resource) and return
      end
      
      # Build puzzle_data
      puzzle_data = {
        'puzzle_clue' => puzzle_clue,
        'clues' => clues
      }
      
      # Optionally generate layout
      if generate_layout
        begin
          crossword_service = CrosswordGeneratorService.new
          layout = crossword_service.generate_layout(clues, smart_order: true)
          puzzle_data['layout'] = {
            'rows' => layout[:rows],
            'cols' => layout[:cols],
            'table' => layout[:table],
            'result' => layout[:result].map do |word|
              {
                'clue' => word[:clue] || word['clue'] || '',
                'answer' => word[:answer] || word['answer'] || '',
                'startx' => word[:startx] || word['startx'] || 1,
                'starty' => word[:starty] || word['starty'] || 1,
                'position' => word[:position] || word['position'] || 1,
                'orientation' => (word[:orientation] || word['orientation'] || 'across').to_s
              }
            end
          }
        rescue => e
          Rails.logger.error "Error generating layout: #{e.message}"
        end
      end
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_edit_krossword_admin_puzzle_path(resource) and return
        end
      end
      
      # Update puzzle
      resource.puzzle_data = puzzle_data
      resource.is_published = params[:is_published] == '1'
      resource.challenge_date = challenge_date
      
      if resource.save
        redirect_to admin_puzzle_path(resource), notice: 'Krossword puzzle updated successfully!'
      else
        flash[:error] = "Error: #{resource.errors.full_messages.join(', ')}"
        redirect_to quick_edit_krossword_admin_puzzle_path(resource)
      end
    else
      # Pre-populate form with existing data
      puzzle_data = resource.puzzle_data || {}
      @puzzle_clue = puzzle_data['puzzle_clue'] || ''
      clues = puzzle_data['clues'] || []
      @clues_text = clues.map { |c| "#{c['clue']} | #{c['answer']}" }.join("\n")
      @challenge_date = resource.challenge_date&.strftime('%Y-%m-%d') || ''
      
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Edit Krossword Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_edit_krossword_admin_puzzle_path(resource) %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Puzzle Clue/Theme (required):</label>
              <input type="text" name="puzzle_clue" value="<%= @puzzle_clue %>" placeholder="e.g., Nature and Wildlife" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Clues (one per line, format: 'Clue text | ANSWER'):</label>
              <textarea name="clues" rows="10" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"><%= @clues_text %></textarea>
              <small style="color: #666;">Enter clues one per line. Format: 'Clue text | ANSWER' (use pipe to separate clue from answer)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="generate_layout" value="1" />
                Generate crossword layout automatically
              </label>
              <small style="color: #666;"> (Optional - layout can be generated later)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" value="<%= @challenge_date %>" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge (Krossword puzzles must be on Sunday)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" <%= 'checked' if resource.is_published %> />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Update Puzzle</button>
              <a href="<%= admin_puzzle_path(resource) %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  member_action :quick_edit_konundrum, method: [:get, :post] do
    if request.post?
      clue = params[:clue] || ''
      words_text = params[:words] || ''
      words = words_text.split("\n").map(&:strip).reject(&:blank?).map(&:upcase)
      
      if words.empty?
        flash[:error] = 'Please provide at least one word'
        redirect_to quick_edit_konundrum_admin_puzzle_path(resource) and return
      end
      
      # Generate seed (use provided or auto-generate)
      seed = params[:seed].present? ? params[:seed] : "konundrum-#{Time.now.to_i * 1000 + rand(1000)}-#{words.join('-')}"
      
      # Shuffle letters (matching JavaScript logic)
      all_letters = words.join('').split('').select { |l| l.match?(/[A-Z]/) }
      shuffled_letters = shuffle_with_seed(all_letters, seed)
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_edit_konundrum_admin_puzzle_path(resource) and return
        end
      end
      
      # Update puzzle
      puzzle_data_hash = {
        'words' => words,
        'letters' => shuffled_letters,
        'seed' => seed
      }
      puzzle_data_hash['clue'] = clue if clue.present?
      
      resource.puzzle_data = puzzle_data_hash
      resource.is_published = params[:is_published] == '1'
      resource.challenge_date = challenge_date
      
      if resource.save
        redirect_to admin_puzzle_path(resource), notice: 'Konundrum puzzle updated successfully!'
      else
        flash[:error] = "Error: #{resource.errors.full_messages.join(', ')}"
        redirect_to quick_edit_konundrum_admin_puzzle_path(resource)
      end
    else
      # Pre-populate form with existing data
      puzzle_data = resource.puzzle_data || {}
      @clue = puzzle_data['clue'] || ''
      words = puzzle_data['words'] || []
      @words_text = words.join("\n")
      @seed = puzzle_data['seed'] || ''
      @challenge_date = resource.challenge_date&.strftime('%Y-%m-%d') || ''
      
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Edit Konundrum Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_edit_konundrum_admin_puzzle_path(resource) %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Clue/Theme (optional):</label>
              <input type="text" name="clue" value="<%= @clue %>" placeholder="e.g., Ocean Life, or leave blank for 'clueless'" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Leave blank for extra difficulty (clueless mode)</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Words (one per line):</label>
              <textarea name="words" rows="5" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"><%= @words_text %></textarea>
              <small style="color: #666;">Enter words one per line. Letters will be automatically shuffled.</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Seed (optional - auto-generated if blank):</label>
              <input type="text" name="seed" value="<%= @seed %>" placeholder="Auto-generated from words and timestamp" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;" />
              <small style="color: #666;">Seed controls letter randomization. Leave blank to auto-generate, or set manually for reproducible shuffling. Current seed: <strong><%= @seed.present? ? @seed : 'Will be auto-generated' %></strong></small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" value="<%= @challenge_date %>" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" <%= 'checked' if resource.is_published %> />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #28a745; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Update Puzzle</button>
              <a href="<%= admin_puzzle_path(resource) %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  member_action :quick_edit_krisskross, method: [:get, :post] do
    if request.post?
      clue = params[:clue] || ''
      words_text = params[:words] || ''
      words = words_text.split("\n").map(&:strip).reject(&:blank?).map(&:upcase)
      
      if words.length < 2
        flash[:error] = 'Please provide at least 2 words (one per line)'
        redirect_to quick_edit_krisskross_admin_puzzle_path(resource) and return
      end
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_edit_krisskross_admin_puzzle_path(resource) and return
        end
      end
      
      # Generate layout using CrosswordGeneratorService
      begin
        crossword_service = CrosswordGeneratorService.new
        words_with_clues = words.map { |w| { 'clue' => '', 'answer' => w } }
        layout = crossword_service.generate_layout(words_with_clues, smart_order: true)
        
        # Update puzzle
        puzzle_data_hash = {
          'words' => words,
          'layout' => {
            'rows' => layout[:rows],
            'cols' => layout[:cols],
            'table' => layout[:table],
            'result' => layout[:result].map do |word|
              {
                'clue' => word[:clue] || word['clue'] || '',
                'answer' => word[:answer] || word['answer'] || '',
                'startx' => word[:startx] || word['startx'] || 1,
                'starty' => word[:starty] || word['starty'] || 1,
                'position' => word[:position] || word['position'] || 1,
                'orientation' => (word[:orientation] || word['orientation'] || 'across').to_s
              }
            end
          }
        }
        
        # Only include clue if it's provided
        puzzle_data_hash['clue'] = clue if clue.present?
        
        resource.puzzle_data = puzzle_data_hash
        resource.is_published = params[:is_published] == '1'
        resource.challenge_date = challenge_date
        
        if resource.save
          redirect_to admin_puzzle_path(resource), notice: 'KrissKross puzzle updated successfully!'
        else
          flash[:error] = "Error: #{resource.errors.full_messages.join(', ')}"
          redirect_to quick_edit_krisskross_admin_puzzle_path(resource)
        end
      rescue => e
        flash[:error] = "Error generating layout: #{e.message}"
        redirect_to quick_edit_krisskross_admin_puzzle_path(resource)
      end
    else
      # Pre-populate form with existing data
      puzzle_data = resource.puzzle_data || {}
      @clue = puzzle_data['clue'] || ''
      words = puzzle_data['words'] || []
      @words_text = words.join("\n")
      @challenge_date = resource.challenge_date&.strftime('%Y-%m-%d') || ''
      
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Edit KrissKross Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_edit_krisskross_admin_puzzle_path(resource) %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Clue/Theme (optional):</label>
              <input type="text" name="clue" value="<%= @clue %>" placeholder="e.g., Ocean, Animals, Food" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Words (one per line, at least 2):</label>
              <textarea name="words" rows="5" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"><%= @words_text %></textarea>
              <small style="color: #666;">Enter at least 2 words. Layout will be automatically regenerated.</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" value="<%= @challenge_date %>" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" <%= 'checked' if resource.is_published %> />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #ff6b35; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Update Puzzle</button>
              <a href="<%= admin_puzzle_path(resource) %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  member_action :quick_edit_konstructor, method: [:get, :post] do
    if request.post?
      puzzle_clue = params[:puzzle_clue] || ''
      words_text = params[:words] || ''
      words = words_text.split("\n").map(&:strip).reject(&:blank?).map(&:upcase)
      
      if words.empty?
        flash[:error] = 'Please provide at least one word'
        redirect_to quick_edit_konstructor_admin_puzzle_path(resource) and return
      end
      
      if puzzle_clue.blank?
        flash[:error] = 'Please provide a puzzle clue'
        redirect_to quick_edit_konstructor_admin_puzzle_path(resource) and return
      end
      
      # Parse challenge_date if provided
      challenge_date = nil
      if params[:challenge_date].present?
        begin
          challenge_date = Date.parse(params[:challenge_date])
        rescue ArgumentError
          flash[:error] = 'Invalid challenge date format'
          redirect_to quick_edit_konstructor_admin_puzzle_path(resource) and return
        end
      end
      
      # Update puzzle
      resource.puzzle_data = {
        'puzzle_clue' => puzzle_clue,
        'words' => words
      }
      resource.is_published = params[:is_published] == '1'
      resource.challenge_date = challenge_date
      
      if resource.save
        redirect_to admin_puzzle_path(resource), notice: 'Konstructor puzzle updated successfully!'
      else
        flash[:error] = "Error: #{resource.errors.full_messages.join(', ')}"
        redirect_to quick_edit_konstructor_admin_puzzle_path(resource)
      end
    else
      # Pre-populate form with existing data
      puzzle_data = resource.puzzle_data || {}
      @puzzle_clue = puzzle_data['puzzle_clue'] || ''
      words = puzzle_data['words'] || []
      @words_text = words.join("\n")
      @challenge_date = resource.challenge_date&.strftime('%Y-%m-%d') || ''
      
      render inline: <<~ERB
        <div style="max-width: 800px; margin: 20px auto; padding: 20px;">
          <h2>Quick Edit Konstructor Puzzle</h2>
          <% if flash[:error] %>
            <div style="color: red; padding: 10px; background: #ffe6e6; border-radius: 5px; margin-bottom: 20px;">
              <%= flash[:error] %>
            </div>
          <% end %>
          
          <form method="post" action="<%= quick_edit_konstructor_admin_puzzle_path(resource) %>">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Puzzle Clue/Theme (required):</label>
              <input type="text" name="puzzle_clue" value="<%= @puzzle_clue %>" placeholder="e.g., Mother Nature's domain" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Words (one per line):</label>
              <textarea name="words" rows="10" required style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; font-family: monospace;"><%= @words_text %></textarea>
              <small style="color: #666;">Enter words one per line. Players will place these on a grid.</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date (optional):</label>
              <input type="date" name="challenge_date" value="<%= @challenge_date %>" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;" />
              <small style="color: #666;">Set a date to make this a daily challenge</small>
            </div>
            
            <div style="margin-bottom: 20px;">
              <label>
                <input type="checkbox" name="is_published" value="1" <%= 'checked' if resource.is_published %> />
                Publish immediately
              </label>
            </div>
            
            <div>
              <button type="submit" style="background: #9b59b6; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">Update Puzzle</button>
              <a href="<%= admin_puzzle_path(resource) %>" style="margin-left: 10px; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; display: inline-block;">Cancel</a>
            </div>
          </form>
        </div>
      ERB
    end
  end
  
  # Member action to preview Konundrum puzzle
  member_action :preview_konundrum, method: :get do
    unless resource.game_type == 'konundrum'
      redirect_to admin_puzzle_path(resource), alert: 'This preview is only available for Konundrum puzzles.'
      return
    end
    
    puzzle_data = resource.puzzle_data || {}
    @clue = puzzle_data['clue'] || ''
    @words = puzzle_data['words'] || []
    @letters = resource.letters || []
    @seed = puzzle_data['seed'] || ''
    
    # Group letters by word sizes
    if @letters.present? && @words.present?
      word_sizes = @words.map(&:length)
      current_index = 0
      @letter_groups = word_sizes.map do |size|
        group = @letters[current_index, size] || []
        current_index += size
        group
      end
    else
      @letter_groups = []
    end
    
    render inline: <<~ERB
      <!DOCTYPE html>
      <html>
      <head>
        <title>Konundrum Puzzle Preview - Puzzle ##{resource.id}</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
          }
          .header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .header h1 {
            margin: 0 0 10px 0;
            color: #28a745;
          }
          .puzzle-container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
          }
          .clue-section {
            margin-bottom: 30px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 6px;
            border-left: 4px solid #28a745;
          }
          .clue-section h3 {
            margin: 0 0 10px 0;
            color: #333;
          }
          .clue-text {
            font-size: 18px;
            color: #666;
            font-style: italic;
          }
          .clueless {
            color: #dc3545;
            font-weight: bold;
          }
          .toggle-section {
            margin-bottom: 20px;
            padding: 15px;
            background: #e7f3ff;
            border-radius: 6px;
            display: flex;
            align-items: center;
            gap: 15px;
          }
          .toggle-switch {
            position: relative;
            display: inline-block;
            width: 60px;
            height: 34px;
          }
          .toggle-switch input {
            opacity: 0;
            width: 0;
            height: 0;
          }
          .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            transition: .4s;
            border-radius: 34px;
          }
          .slider:before {
            position: absolute;
            content: "";
            height: 26px;
            width: 26px;
            left: 4px;
            bottom: 4px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
          }
          input:checked + .slider {
            background-color: #28a745;
          }
          input:checked + .slider:before {
            transform: translateX(26px);
          }
          .letters-grid {
            display: flex;
            flex-direction: column;
            gap: 20px;
          }
          .word-row {
            display: flex;
            flex-direction: column;
            gap: 10px;
          }
          .word-label {
            font-size: 14px;
            color: #666;
            font-weight: 600;
            margin-bottom: 5px;
          }
          .letters-display {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
          }
          .letter-tile {
            width: 50px;
            height: 50px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #fff;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 24px;
            font-weight: bold;
            color: #333;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .letter-tile.solved {
            background: #d4edda;
            border-color: #28a745;
            color: #155724;
          }
          .solution-word {
            font-size: 20px;
            font-weight: bold;
            color: #28a745;
            margin-left: 10px;
          }
          .solution-word.hidden {
            display: none;
          }
          .back-link {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 20px;
            background: #6c757d;
            color: white;
            text-decoration: none;
            border-radius: 5px;
          }
          .back-link:hover {
            background: #5a6268;
          }
          .info-section {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            margin-top: 20px;
            font-size: 14px;
            color: #666;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Konundrum Puzzle Preview</h1>
          <p>Puzzle ID: ##{resource.id} | Created: #{resource.created_at.strftime('%Y-%m-%d %H:%M')}</p>
        </div>
        
        <div class="puzzle-container">
          <% if @clue.present? %>
            <div class="clue-section">
              <h3>Clue/Theme:</h3>
              <div class="clue-text"><%= @clue %></div>
            </div>
          <% else %>
            <div class="clue-section">
              <h3>Clue/Theme:</h3>
              <div class="clue-text clueless">CLUELESS MODE</div>
            </div>
          <% end %>
          
          <div class="toggle-section">
            <label class="toggle-switch">
              <input type="checkbox" id="showSolution" onchange="toggleSolution()">
              <span class="slider"></span>
            </label>
            <label for="showSolution" style="font-size: 16px; font-weight: 600; color: #333; cursor: pointer;">
              Show Solution
            </label>
          </div>
          
          <div class="letters-grid">
            <% @letter_groups.each_with_index do |letter_group, word_index| %>
              <div class="word-row">
                <div class="word-label">
                  Word <%= word_index + 1 %> (<%= letter_group.length %> letters)
                  <span class="solution-word hidden" id="solution-<%= word_index %>">
                    → <%= @words[word_index] %>
                  </span>
                </div>
                <div class="letters-display">
                  <% letter_group.each_with_index do |letter, letter_index| %>
                    <div class="letter-tile" id="tile-<%= word_index %>-<%= letter_index %>">
                      <%= letter %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
          
          <div class="info-section">
            <strong>Seed:</strong> <code><%= @seed.present? ? @seed : 'Not set' %></code><br>
            <strong>Words:</strong> <%= @words.join(', ') %><br>
            <strong>Total Letters:</strong> <%= @letters.length %>
          </div>
        </div>
        
        <a href="<%= admin_puzzle_path(resource) %>" class="back-link">← Back to Puzzle</a>
        
        <script>
          function toggleSolution() {
            const showSolution = document.getElementById('showSolution').checked;
            const solutionWords = document.querySelectorAll('.solution-word');
            const letterTiles = document.querySelectorAll('.letter-tile');
            
            solutionWords.forEach(word => {
              if (showSolution) {
                word.classList.remove('hidden');
              } else {
                word.classList.add('hidden');
              }
            });
            
            letterTiles.forEach(tile => {
              if (showSolution) {
                tile.classList.add('solved');
              } else {
                tile.classList.remove('solved');
              }
            });
          }
        </script>
      </body>
      </html>
    ERB
  end
  
  # Member action to regenerate letters for Konundrum puzzles
  member_action :regenerate_letters, method: :post do
    if resource.game_type != 'konundrum'
      redirect_to admin_puzzle_path(resource), alert: 'This action is only available for Konundrum puzzles.'
      return
    end
    
    puzzle_data = resource.puzzle_data || {}
    clue = puzzle_data['clue'] || ''
    words = puzzle_data['words'] || []
    
    if words.empty?
      redirect_to admin_puzzle_path(resource), alert: 'Cannot regenerate letters: no words found in puzzle data.'
      return
    end
    
    # Generate new seed with current timestamp (matching JavaScript format)
    seed = "konundrum-#{Time.now.to_i * 1000 + rand(1000)}-#{words.join('-')}"
    
    # Collect all letters from all words
    all_letters = words.join('').split('').select { |l| l.match?(/[A-Z]/) }
    
    # Shuffle using seeded random (matching JavaScript logic)
    # Create hash from seed (matching JavaScript hash function)
    hash = 0
    seed.each_byte do |byte|
      hash = ((hash << 5) - hash) + byte
      hash = hash & hash # Convert to 32bit integer
    end
    
    # Fisher-Yates shuffle with seeded random
    shuffled = all_letters.dup
    seed_value = hash.abs
    
    (shuffled.length - 1).downto(1) do |i|
      # Generate pseudo-random index using seed (matching JavaScript PRNG)
      seed_value = (seed_value * 9301 + 49297) % 233280
      j = ((seed_value.to_f / 233280) * (i + 1)).floor
      shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    shuffled_letters = shuffled
    
    # Split shuffled letters into groups based on word sizes
    word_sizes = words.map(&:length)
    current_index = 0
    letter_groups = word_sizes.map do |size|
      group = shuffled_letters[current_index, size]
      current_index += size
      group
    end
    
    # Update puzzle_data
    resource.puzzle_data = {
      clue: clue,
      words: words,
      letters: shuffled_letters,
      seed: seed,
      letterGroups: letter_groups
    }
    
    if resource.save
      redirect_to admin_puzzle_path(resource), notice: 'Letters have been regenerated with a new random shuffle!'
    else
      redirect_to admin_puzzle_path(resource), alert: "Error regenerating letters: #{resource.errors.full_messages.join(', ')}"
    end
  end

  # Index page configuration
  index do
    selectable_column
    id_column
    column :game_type do |puzzle|
      case puzzle.game_type
      when 'krossword'
        content_tag :span, "Krossword", 
          class: "status_tag",
          style: "background-color: #007bff; color: white;"
      when 'konundrum'
        content_tag :span, "Konundrum", 
          class: "status_tag",
          style: "background-color: #28a745; color: white;"
      when 'krisskross'
        content_tag :span, "KrissKross", 
          class: "status_tag",
          style: "background-color: #ff6b35; color: white;"
      when 'konstructor'
        content_tag :span, "Konstructor", 
          class: "status_tag",
          style: "background-color: #9b59b6; color: white;"
      else
        content_tag :span, "Krossword (Legacy)", 
          class: "status_tag",
          style: "background-color: #6c757d; color: white;"
      end
    end
    column :challenge_date do |puzzle|
      puzzle.challenge_date&.strftime('%Y-%m-%d')
    end
    column :is_published do |puzzle|
      puzzle.is_published? ? 'True' : 'False'
    end
    column :created_at
    actions do |puzzle|
      link_to 'View Puzzle', puzzle_preview_path(puzzle), 
        target: '_blank', 
        class: 'member_link',
        style: 'background-color: #007bff; color: white; padding: 5px 10px; text-decoration: none; border-radius: 3px;'
    end
  end

  # Show page configuration
  show do
    div style: 'margin-bottom: 20px;' do
      link_to 'View Puzzle Preview', puzzle_preview_path(puzzle), 
        target: '_blank', 
        class: 'button',
        style: 'background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold;'
    end
    
    attributes_table do
      row :id
      row :game_type do |puzzle|
        case puzzle.game_type
        when 'krossword'
          content_tag :span, "Krossword", 
            style: "background-color: #007bff; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        when 'konundrum'
          content_tag :span, "Konundrum", 
            style: "background-color: #28a745; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        when 'krisskross'
          content_tag :span, "KrissKross", 
            style: "background-color: #ff6b35; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        when 'konstructor'
          content_tag :span, "Konstructor", 
            style: "background-color: #9b59b6; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        else
          "Krossword (Legacy)"
        end
      end
      row :puzzle_data do |puzzle|
        if puzzle.puzzle_data.present?
          content_tag :pre, JSON.pretty_generate(puzzle.puzzle_data), 
            style: "max-height: 400px; overflow: auto; background: #f5f5f5; padding: 10px; border-radius: 4px;"
        else
          'No puzzle data'
        end
      end
      row :is_published do |puzzle|
        puzzle.is_published? ? 'True' : 'False'
      end
      row :challenge_date do |puzzle|
        puzzle.challenge_date&.strftime('%Y-%m-%d') || 'N/A'
      end
      row :created_at
      row :updated_at
    end
  end

  # Form configuration
  form do |f|
    f.inputs "Puzzle Details" do
      f.input :game_type, as: :select, collection: [
        ['Krossword', 'krossword'],
        ['Konundrum', 'konundrum'],
        ['KrissKross', 'krisskross'],
        ['Konstructor', 'konstructor']
      ], hint: "Select the game type for this puzzle"
      f.input :is_published, as: :boolean
    end
    
    f.inputs "Puzzle Type (Challenge)" do
      f.input :challenge_date, as: :string, 
        input_html: { type: 'date' },
        hint: "Set a date to make this a challenge. Note: Krossword puzzles must be on Sunday."
    end
    
    # Conditional inputs based on game_type
    # Note: This requires JavaScript to show/hide fields, but for now we'll show all
    f.inputs "Puzzle Content" do
      f.input :description, as: :text, input_html: { rows: 4 },
        hint: "Description (for Krossword puzzles - legacy, use puzzle_data instead)"
      f.input :puzzle_data, as: :text,
        input_html: {
          rows: 15,
          value: f.object.puzzle_data.present? ? JSON.pretty_generate(f.object.puzzle_data) : '',
          placeholder: 'Enter puzzle_data as JSON object. Structure depends on game_type.'
        },
        hint: "Puzzle Data (JSON) - Required for Konundrum and KrissKross. See PUZZLE_DATA_STRUCTURE.md for format."
    end
    
    f.actions
  end

  # Filters
  filter :title
  filter :description
  filter :game_type, as: :select, collection: [
    ['Krossword', 'krossword'],
    ['Konundrum', 'konundrum'],
    ['KrissKross', 'krisskross'],
    ['Konstructor', 'konstructor']
  ]
  filter :challenge_date, as: :date_range
  filter :is_published, as: :select, collection: [['True', true], ['False', false]]
  filter :created_at
  filter :updated_at


end
