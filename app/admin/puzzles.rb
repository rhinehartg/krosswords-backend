require 'json'

ActiveAdmin.register Puzzle do
  # Permit parameters for puzzle management
  permit_params :title, :description, :difficulty, :rating, :is_published, :clues, :is_featured, :challenge_date, :game_type, :puzzle_data
  
  controller do
    # Before save, parse puzzle_data if it's a string
    before_action :parse_puzzle_data, only: [:create, :update]
    
    private
    
    def parse_puzzle_data
      if params[:puzzle] && params[:puzzle][:puzzle_data].is_a?(String) && params[:puzzle][:puzzle_data].present?
        begin
          params[:puzzle][:puzzle_data] = JSON.parse(params[:puzzle][:puzzle_data])
        rescue JSON::ParserError => e
          @puzzle = Puzzle.new(puzzle_params.except(:puzzle_data))
          @puzzle.errors.add(:puzzle_data, "Invalid JSON: #{e.message}")
          render :edit, status: :unprocessable_entity and return
        end
      end
    end
  end

  # Add custom action for AI puzzle generation
  action_item :generate_ai_puzzle, only: :index do
    link_to 'Generate AI Puzzle', '#', 
      onclick: 'showAIPuzzleModal(); return false;',
      class: 'button',
      style: 'background-color: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold; margin-right: 10px;'
  end
  
  # Add custom action for daily challenge generation
  action_item :generate_daily_challenge, only: :index do
    link_to 'Generate Daily Challenge', '#', 
      onclick: 'showDailyChallengeModal(); return false;',
      class: 'button',
      style: 'background-color: #ff6b35; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold;'
  end

  # Index page configuration
  index do
    selectable_column
    id_column
    column :title
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
      else
        content_tag :span, "Krossword (Legacy)", 
          class: "status_tag",
          style: "background-color: #6c757d; color: white;"
      end
    end
    column :description_or_clue do |puzzle|
      text = case puzzle.game_type
      when 'konundrum', 'krisskross'
        puzzle.clue || puzzle.puzzle_data&.dig('clue') || 'N/A'
      else
        puzzle.description || 'N/A'
      end
      truncate(text, length: 50)
    end
    column "Challenge Status" do |puzzle|
      if puzzle.daily_challenge?
        content_tag :span, "Daily Challenge", 
          class: "status_tag daily_challenge",
          style: "background-color: #ff6b35; color: white;"
      elsif puzzle.featured?
        content_tag :span, "Featured", 
          class: "status_tag featured",
          style: "background-color: #28a745; color: white;"
      else
        content_tag :span, "Regular", 
          class: "status_tag regular",
          style: "background-color: #6c757d; color: white;"
      end
    end
    column :difficulty do |puzzle|
      case puzzle.difficulty
      when 'Easy'
        content_tag :span, puzzle.difficulty, 
          style: "background-color: #d4edda; color: #155724; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
      when 'Medium'
        content_tag :span, puzzle.difficulty, 
          style: "background-color: #fff3cd; color: #856404; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
      when 'Hard'
        content_tag :span, puzzle.difficulty, 
          style: "background-color: #f8d7da; color: #721c24; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
      else
        puzzle.difficulty
      end
    end
    column :rating do |puzzle|
      "#{puzzle.average_rating} (#{puzzle.rating_count})"
    end
    column :content_info do |puzzle|
      case puzzle.game_type
      when 'konundrum'
        words = puzzle.words || puzzle.puzzle_data&.dig('words') || []
        "#{words.length} words"
      when 'krisskross'
        words = puzzle.krisskross_words || puzzle.puzzle_data&.dig('words') || []
        "#{words.length} words"
      else
        "#{puzzle.clues_count} clues"
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
      row :title
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
        else
          "Krossword (Legacy)"
        end
      end
      row :description do |puzzle|
        puzzle.description.presence || 'N/A'
      end
      row :clue do |puzzle|
        if puzzle.game_type == 'konundrum' || puzzle.game_type == 'krisskross'
          puzzle.clue || puzzle.puzzle_data&.dig('clue') || 'N/A'
        else
          'N/A (Krossword puzzles use description)'
        end
      end
      row :difficulty do |puzzle|
        case puzzle.difficulty
        when 'Easy'
          content_tag :span, puzzle.difficulty, 
            style: "background-color: #d4edda; color: #155724; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        when 'Medium'
          content_tag :span, puzzle.difficulty, 
            style: "background-color: #fff3cd; color: #856404; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        when 'Hard'
          content_tag :span, puzzle.difficulty, 
            style: "background-color: #f8d7da; color: #721c24; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        else
          puzzle.difficulty
        end
      end
      row :rating do |puzzle|
        "#{puzzle.average_rating} (#{puzzle.rating_count})"
      end
      row :content_info do |puzzle|
        case puzzle.game_type
        when 'konundrum'
          words = puzzle.words || puzzle.puzzle_data&.dig('words') || []
          letters = puzzle.letters || puzzle.puzzle_data&.dig('letters') || []
          "Words: #{words.join(', ')} (#{words.length} total)<br>Letters: #{letters.length} shuffled".html_safe
        when 'krisskross'
          words = puzzle.krisskross_words || puzzle.puzzle_data&.dig('words') || []
          "Words: #{words.join(', ')} (#{words.length} total)".html_safe
        else
          "Clues Count: #{puzzle.clues_count}"
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
      row :clues do |puzzle|
        # Only show clues for krossword puzzles
        if puzzle.game_type == 'konundrum' || puzzle.game_type == 'krisskross'
          "N/A - #{puzzle.game_type&.capitalize} puzzles don't use clues"
        elsif puzzle.clues.present?
          content_tag :div, class: 'clues-display' do
            begin
              # Parse clues if it's a string, otherwise use as-is
              clues_array = if puzzle.clues.is_a?(String)
                # Try JSON first, then fall back to eval for Ruby hash format
                begin
                  JSON.parse(puzzle.clues)
                rescue JSON::ParserError
                  # Handle Ruby hash format (e.g., "clue" => "answer")
                  eval(puzzle.clues)
                end
              else
                puzzle.clues
              end
              
              clues_array.map do |clue_data|
                content_tag :div, class: 'clue-item' do
                  content_tag(:strong, "Clue: ") + 
                  clue_data['clue'] + 
                  content_tag(:br) +
                  content_tag(:em, "Answer: ") + 
                  clue_data['answer']
                end
              end.join.html_safe
            rescue => e
              content_tag :div, class: 'error-message' do
                "Error parsing clues: #{e.message}<br>Raw data: #{puzzle.clues.inspect}"
              end
            end
          end
        else
          "No clues"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  # Form configuration
  form do |f|
    f.inputs "Puzzle Details" do
      f.input :title
      f.input :game_type, as: :select, collection: [
        ['Krossword', 'krossword'],
        ['Konundrum', 'konundrum'],
        ['KrissKross', 'krisskross']
      ], hint: "Select the game type for this puzzle"
      f.input :difficulty, as: :select, collection: [
        ['Easy', 'Easy'],
        ['Medium', 'Medium'], 
        ['Hard', 'Hard']
      ], hint: "Easy = Green, Medium = Yellow, Hard = Red"
      f.input :rating, as: :select, collection: [1, 2, 3], 
        hint: "1 = 1 star, 2 = 2 stars, 3 = 3 stars"
      f.input :is_published, as: :boolean
      f.input :is_featured, as: :boolean, 
        hint: "Mark this puzzle as featured"
    end
    
    f.inputs "Puzzle Type (Challenge)" do
      f.input :challenge_date, as: :string, 
        input_html: { type: 'date' },
        hint: "Set a date to make this a daily challenge (leave blank for regular puzzle)"
    end
    
    # Conditional inputs based on game_type
    # Note: This requires JavaScript to show/hide fields, but for now we'll show all
    f.inputs "Puzzle Content" do
      f.input :description, as: :text, input_html: { rows: 4 },
        hint: "Description (for Krossword puzzles)"
      f.input :clues, as: :text, 
        input_html: { 
          rows: 10,
          placeholder: 'Enter clues as JSON array, e.g.: [{"clue": "Man\'s best friend", "answer": "DOG"}]'
        },
        hint: "Clues (for Krossword puzzles only)"
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
    ['KrissKross', 'krisskross']
  ]
  filter :difficulty, as: :select, collection: ['Easy', 'Medium', 'Hard']
  filter :rating, as: :select, collection: [1, 2, 3]
  filter :is_published, as: :select, collection: [['True', true], ['False', false]]
  filter :created_at
  filter :updated_at


end
