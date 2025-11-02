ActiveAdmin.register GameSession do
  # Permit parameters (read-only for now, or minimal editing)
  permit_params :status, :game_state

  # Index page configuration
  index do
    selectable_column
    id_column
    column :user do |session|
      link_to session.user.email, admin_user_path(session.user)
    end
    column :puzzle do |session|
      link_to session.puzzle.title, admin_puzzle_path(session.puzzle)
    end
    column :game_type do |session|
      case session.puzzle.game_type
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
    column :status do |session|
      case session.status
      when 'active'
        content_tag :span, "Active", 
          style: "background-color: #28a745; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
      when 'completed'
        content_tag :span, "Completed", 
          style: "background-color: #007bff; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
      when 'abandoned'
        content_tag :span, "Abandoned", 
          style: "background-color: #6c757d; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
      else
        session.status
      end
    end
    column :progress_info do |session|
      state = session.game_state || {}
      if state['gameCompleted']
        "Completed"
      elsif state['userInput'] && state['userInput'].is_a?(Hash)
        filled_cells = state['userInput'].values.count { |v| v.present? }
        if state['completedWords']
          completed = state['completedWords'].length
          "#{completed} words completed, #{filled_cells} cells filled"
        else
          "#{filled_cells} cells filled"
        end
      elsif state['wordStates']
        completed = state['wordStates'].count { |w| w['isComplete'] } rescue 0
        "#{completed} words completed"
      else
        "Not started"
      end
    end
    column :started_at do |session|
      session.started_at.strftime('%Y-%m-%d %H:%M')
    end
    column :completed_at do |session|
      session.completed_at&.strftime('%Y-%m-%d %H:%M') || '-'
    end
    column :duration do |session|
      if session.completed_at && session.started_at
        duration = session.completed_at - session.started_at
        hours = (duration / 3600).to_i
        minutes = ((duration % 3600) / 60).to_i
        seconds = (duration % 60).to_i
        if hours > 0
          "#{hours}h #{minutes}m"
        elsif minutes > 0
          "#{minutes}m #{seconds}s"
        else
          "#{seconds}s"
        end
      elsif session.started_at
        duration = Time.current - session.started_at
        hours = (duration / 3600).to_i
        minutes = ((duration % 3600) / 60).to_i
        if hours > 0
          "#{hours}h #{minutes}m (ongoing)"
        else
          "#{minutes}m (ongoing)"
        end
      else
        '-'
      end
    end
    actions
  end

  # Show page configuration
  show do
    attributes_table do
      row :id
      row :user do |session|
        link_to session.user.email, admin_user_path(session.user)
      end
      row :puzzle do |session|
        link_to session.puzzle.title, admin_puzzle_path(session.puzzle)
      end
      row :game_type do |session|
        case session.puzzle.game_type
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
      row :status do |session|
        case session.status
        when 'active'
          content_tag :span, "Active", 
            style: "background-color: #28a745; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        when 'completed'
          content_tag :span, "Completed", 
            style: "background-color: #007bff; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        when 'abandoned'
          content_tag :span, "Abandoned", 
            style: "background-color: #6c757d; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;"
        else
          session.status
        end
      end
      row :started_at
      row :completed_at
      row :duration do |session|
        if session.completed_at && session.started_at
          duration = session.completed_at - session.started_at
          hours = (duration / 3600).to_i
          minutes = ((duration % 3600) / 60).to_i
          seconds = (duration % 60).to_i
          "#{hours} hours, #{minutes} minutes, #{seconds} seconds"
        elsif session.started_at
          duration = Time.current - session.started_at
          hours = (duration / 3600).to_i
          minutes = ((duration % 3600) / 60).to_i
          seconds = (duration % 60).to_i
          "#{hours} hours, #{minutes} minutes, #{seconds} seconds (ongoing)"
        else
          'N/A'
        end
      end
      row :created_at
      row :updated_at
    end

    # Game State Section
    div style: 'margin-top: 30px;' do
      h3 'Game State'
      if game_session.game_state.present? && game_session.game_state.is_a?(Hash)
        div style: 'background: #f5f5f5; padding: 15px; border-radius: 5px;' do
          state = game_session.game_state
          
          # Krossword-specific state
          if state['userInput'] || state['completedWords'] || state['revealedClues']
            h4 'Krossword Progress'
            if state['userInput'] && state['userInput'].is_a?(Hash)
              filled = state['userInput'].values.count { |v| v.present? }
              div "Filled Cells: #{filled} / #{state['userInput'].keys.length}"
            end
            if state['completedWords']
              div "Completed Words: #{state['completedWords'].length}"
              if state['completedWords'].length > 0
                div style: 'margin-left: 20px; margin-top: 5px;' do
                  state['completedWords'].first(5).each do |word_key|
                    div word_key
                  end
                  if state['completedWords'].length > 5
                    div "... and #{state['completedWords'].length - 5} more"
                  end
                end
              end
            end
            if state['revealedClues']
              div "Revealed Clues: #{state['revealedClues'].length}"
            end
            if state['revealedWords']
              div "Revealed Words: #{state['revealedWords'].length}"
            end
            if state['gameCompleted']
              div style: 'color: green; font-weight: bold;' do
                "✓ Game Completed"
              end
            end
          end
          
          # Konundrum/KrissKross-specific state
          if state['wordStates']
            h4 'Word States'
            completed = state['wordStates'].count { |w| w['isComplete'] rescue false }
            div "Completed: #{completed} / #{state['wordStates'].length}"
          end
          
          if state['score']
            div "Score: #{state['score']}"
          end
          
          if state['checkCount']
            div "Check Count: #{state['checkCount']}"
          end
          
          if state['isComplete']
            div style: 'color: green; font-weight: bold;' do
              "✓ Puzzle Complete"
            end
          end
          
          # Raw JSON view
          div style: 'margin-top: 15px;' do
            content_tag(:details) do
              content_tag(:summary, 'View Raw Game State JSON', style: 'cursor: pointer; font-weight: bold;') +
              content_tag(:pre, JSON.pretty_generate(state), 
                style: "max-height: 400px; overflow: auto; background: white; padding: 10px; border: 1px solid #ddd; border-radius: 4px; margin-top: 10px;")
            end
          end
        end
      else
        div 'No game state saved yet'
      end
    end
  end

  # Form configuration (minimal, mostly read-only)
  form do |f|
    f.inputs "Session Details" do
      f.input :user, input_html: { disabled: true }
      f.input :puzzle, input_html: { disabled: true }
      f.input :status, as: :select, collection: [
        ['Active', 'active'],
        ['Completed', 'completed'],
        ['Abandoned', 'abandoned']
      ]
      f.input :game_state, as: :text,
        input_html: {
          rows: 15,
          value: f.object.game_state.present? ? JSON.pretty_generate(f.object.game_state) : '',
          placeholder: 'Game state as JSON'
        },
        hint: "Game state (JSON) - Usually auto-managed by the application"
    end
    f.actions
  end

  # Filters
  filter :user, as: :select, collection: -> { User.order(:email).map { |u| [u.email, u.id] } }
  filter :puzzle, as: :select, collection: -> { Puzzle.order(:title).map { |p| ["#{p.title} (#{p.game_type})", p.id] } }
  filter :status, as: :select, collection: [['Active', 'active'], ['Completed', 'completed'], ['Abandoned', 'abandoned']]
  filter :started_at
  filter :completed_at
  filter :created_at
  filter :updated_at

  # Scopes for quick filtering
  scope :all, default: true
  scope :active
  scope :completed
  scope :abandoned

  # Batch actions
  batch_action :mark_as_completed do |ids|
    sessions = GameSession.where(id: ids)
    sessions.find_each do |session|
      session.update_columns(status: 'completed', completed_at: Time.current, updated_at: Time.current)
    end
    redirect_to collection_path, notice: "Marked #{ids.count} session(s) as completed"
  end

  batch_action :mark_as_abandoned do |ids|
    sessions = GameSession.where(id: ids)
    sessions.find_each do |session|
      session.update_columns(status: 'abandoned', updated_at: Time.current)
    end
    redirect_to collection_path, notice: "Marked #{ids.count} session(s) as abandoned"
  end

  # Controller customizations
  controller do
    def scoped_collection
      super.includes(:user, :puzzle)
    end
  end
end

