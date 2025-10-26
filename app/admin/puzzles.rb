ActiveAdmin.register Puzzle do
  # Permit parameters for puzzle management
  permit_params :title, :description, :difficulty, :rating, :is_published, :clues

  # Add custom action for AI puzzle generation
  action_item :generate_ai_puzzle, only: :index do
    link_to '🤖 Generate AI Puzzle', '#', 
      onclick: 'showAIPuzzleModal(); return false;',
      class: 'button',
      style: 'background-color: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold; margin-right: 10px;'
  end

  # Index page configuration
  index do
    selectable_column
    id_column
    column :title
    column :description do |puzzle|
      truncate(puzzle.description, length: 50)
    end
    column :difficulty do |puzzle|
      status_tag puzzle.difficulty, 
        class: puzzle.easy? ? 'green' : puzzle.medium? ? 'orange' : 'red'
    end
    column :rating do |puzzle|
      "⭐" * puzzle.rating
    end
    column :clues_count do |puzzle|
      puzzle.clues_count
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
        status_tag puzzle.difficulty,
          class: puzzle.easy? ? 'green' : puzzle.medium? ? 'orange' : 'red'
      end
      row :rating do |puzzle|
        "⭐" * puzzle.rating
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
            puzzle.clues.map do |clue_data|
              content_tag :div, class: 'clue-item' do
                content_tag(:strong, "Clue: ") + 
                clue_data['clue'] + 
                content_tag(:br) +
                content_tag(:em, "Answer: ") + 
                clue_data['answer']
              end
            end.join.html_safe
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
      f.input :difficulty, as: :select, collection: ['Easy', 'Medium', 'Hard']
      f.input :rating, as: :select, collection: [1, 2, 3], 
        hint: "1 = ⭐, 2 = ⭐⭐, 3 = ⭐⭐⭐"
      f.input :is_published, as: :boolean
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
