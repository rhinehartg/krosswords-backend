require 'json'

ActiveAdmin.register Puzzle do
  # Permit parameters for puzzle management
  permit_params :title, :description, :difficulty, :rating, :is_published, :clues, :is_featured, :challenge_date

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
    column :description do |puzzle|
      truncate(puzzle.description, length: 50)
    end
    column :puzzle_type do |puzzle|
      case puzzle
      when DailyChallenge
        content_tag :span, "Daily Challenge", 
          class: "status_tag daily_challenge",
          style: "background-color: #ff6b35; color: white;"
      else
        if puzzle.featured?
          content_tag :span, "Featured", 
            class: "status_tag featured",
            style: "background-color: #28a745; color: white;"
        else
          content_tag :span, "Regular", 
            class: "status_tag regular",
            style: "background-color: #6c757d; color: white;"
        end
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
    column :clues_count do |puzzle|
      puzzle.clues_count
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
      row :description
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
      row :clues_count do |puzzle|
        puzzle.clues_count
      end
      row :is_published do |puzzle|
        puzzle.is_published? ? 'True' : 'False'
      end
      row :clues do |puzzle|
        if puzzle.clues.present?
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
      f.input :description, as: :text, input_html: { rows: 4 }
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
    
    f.inputs "Puzzle Type" do
      f.input :challenge_date, as: :string, 
        input_html: { type: 'date' },
        hint: "Set a date to make this a daily challenge (leave blank for regular puzzle)"
    end
    
    f.inputs "Clues" do
      f.input :clues, as: :text, 
        input_html: { 
          rows: 10,
          placeholder: 'Enter clues as JSON array, e.g.: [{"clue": "Man\'s best friend", "answer": "DOG"}, {"clue": "King of the jungle", "answer": "LION"}]'
        },
        hint: "Enter clues as a JSON array with 'clue' and 'answer' fields"
    end
    
    f.actions
  end

  # Filters
  filter :title
  filter :description
  filter :difficulty, as: :select, collection: ['Easy', 'Medium', 'Hard']
  filter :rating, as: :select, collection: [1, 2, 3]
  filter :is_published, as: :select, collection: [['True', true], ['False', false]]
  filter :created_at
  filter :updated_at


end
