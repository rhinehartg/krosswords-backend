ActiveAdmin.register Rating do
  # Permit parameters for rating management
  permit_params :user_id, :puzzle_id, :rating

  # Index page configuration
  index do
    selectable_column
    id_column
    column :user do |rating|
      link_to rating.user.email, admin_user_path(rating.user)
    end
    column :puzzle do |rating|
      puzzle_display = "#{rating.puzzle.game_type || 'Puzzle'} - #{rating.puzzle.challenge_date&.strftime('%b %d, %Y') || 'No date'}"
      link_to puzzle_display, admin_puzzle_path(rating.puzzle)
    end
    column :rating do |rating|
      "#{rating.rating} stars"
    end
    column :created_at
    actions
  end

  # Show page configuration
  show do
    attributes_table do
      row :id
      row :user do |rating|
        link_to rating.user.email, admin_user_path(rating.user)
      end
      row :puzzle do |rating|
        puzzle_display = "#{rating.puzzle.game_type || 'Puzzle'} - #{rating.puzzle.challenge_date&.strftime('%b %d, %Y') || 'No date'}"
        link_to puzzle_display, admin_puzzle_path(rating.puzzle)
      end
      row :rating do |rating|
        "#{rating.rating} stars"
      end
      row :created_at
      row :updated_at
    end
  end

  # Form configuration
  form do |f|
    f.inputs "Rating Details" do
      f.input :user, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }
      f.input :puzzle, as: :select, collection: -> { Puzzle.all.map { |p| [p.title, p.id] } }
      f.input :rating, as: :select, collection: [1, 2, 3], 
        hint: "1 = 1 star, 2 = 2 stars, 3 = 3 stars"
    end
    f.actions
  end

  # Filters
  filter :user, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }
  filter :puzzle, as: :select, collection: -> { Puzzle.all.map { |p| [p.title, p.id] } }
  filter :rating, as: :select, collection: [1, 2, 3]
  filter :created_at
end
