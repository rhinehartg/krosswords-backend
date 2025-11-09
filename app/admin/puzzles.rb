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

  # Add custom action for AI puzzle generation
  action_item :generate_ai_puzzle, only: [:index, :new] do
    link_to 'Generate AI Puzzle', '#', 
      onclick: 'showAIPuzzleModal(); return false;',
      style: 'background-color: #d4edda !important; color: #155724 !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #28a745 !important; display: inline-block; cursor: pointer;'
  end
  
  
  # Add regenerate letters button for Konundrum puzzles
  action_item :regenerate_letters, only: [:show, :edit] do
    if resource.game_type == 'konundrum' && resource.puzzle_data.present? && resource.puzzle_data['words'].present?
      link_to 'Regenerate Letters', regenerate_letters_admin_puzzle_path(resource),
        method: :post,
        data: { confirm: 'This will generate a new random shuffle of the letters. Continue?' },
        style: 'background-color: #e0e7ff !important; color: #1e3a8a !important; padding: 10px 20px; text-decoration: none !important; border-radius: 5px; font-weight: bold; margin-right: 10px; border: 2px solid #667eea !important; display: inline-block; cursor: pointer;'
    end
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
