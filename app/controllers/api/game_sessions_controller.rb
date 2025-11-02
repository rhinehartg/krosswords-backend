class Api::GameSessionsController < ApplicationController
  before_action :authenticate_api_user!

  # GET /api/game_sessions/puzzle/:puzzle_id
  # Get or create a session for the current user and puzzle
  def show_or_create
    puzzle = Puzzle.find(params[:puzzle_id])
    
    # Find existing session or create a new one
    # Use find_or_create_by with rescue to handle race conditions
    session = current_user.game_sessions.find_or_create_by(puzzle: puzzle) do |s|
      s.status = 'active'
      s.started_at = Time.current
      s.game_state = {}
    end
    
    render json: {
      success: true,
      session: session_json(session)
    }
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
    # Race condition: session was created by another request, find it
    session = current_user.game_sessions.find_by(puzzle: puzzle)
    if session
      render json: {
        success: true,
        session: session_json(session)
      }
    else
      raise e
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Puzzle not found'
    }, status: :not_found
  rescue => e
    Rails.logger.error "GameSession creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: {
      success: false,
      error: 'Failed to create session',
      details: e.message
    }, status: :internal_server_error
  end

  # GET /api/game_sessions/:id
  # Get a specific session
  def show
    session = current_user.game_sessions.find(params[:id])
    
    render json: {
      success: true,
      session: session_json(session)
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Session not found'
    }, status: :not_found
  end

  # POST /api/game_sessions
  # Create a new session (will find existing if one exists)
  def create
    puzzle = Puzzle.find(session_params[:puzzle_id])
    
    # Check if session already exists
    existing_session = current_user.game_sessions.find_by(puzzle: puzzle)
    
    if existing_session
      render json: {
        success: true,
        session: session_json(existing_session),
        message: 'Session already exists'
      }
      return
    end
    
    # Create new session
    session = current_user.game_sessions.build(
      puzzle: puzzle,
      game_state: session_params[:game_state] || {},
      status: 'active'
    )
    
    if session.save
      render json: {
        success: true,
        session: session_json(session),
        message: 'Session created successfully'
      }, status: :created
    else
      render json: {
        success: false,
        error: 'Failed to create session',
        errors: session.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Puzzle not found'
    }, status: :not_found
  end

  # PUT /api/game_sessions/:id
  # Update session (mainly game_state)
  def update
    session = current_user.game_sessions.find(params[:id])
    
    # Deep merge game_state if provided
    if session_params[:game_state].present?
      new_state = session.game_state.deep_merge(session_params[:game_state])
      session_params_hash = session_params.to_h
      session_params_hash[:game_state] = new_state
      
      if session.update(session_params_hash.except(:puzzle_id))
        render json: {
          success: true,
          session: session_json(session),
          message: 'Session updated successfully'
        }
      else
        render json: {
          success: false,
          error: 'Failed to update session',
          errors: session.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      if session.update(session_params.except(:puzzle_id, :game_state))
        render json: {
          success: true,
          session: session_json(session),
          message: 'Session updated successfully'
        }
      else
        render json: {
          success: false,
          error: 'Failed to update session',
          errors: session.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Session not found'
    }, status: :not_found
  end

  # PUT /api/game_sessions/:id/complete
  # Mark session as completed
  def complete
    session = current_user.game_sessions.find(params[:id])
    
    session.complete!
    
    render json: {
      success: true,
      session: session_json(session),
      message: 'Session completed successfully'
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Session not found'
    }, status: :not_found
  end

  # DELETE /api/game_sessions/:id
  # Delete or abandon a session
  def destroy
    session = current_user.game_sessions.find(params[:id])
    
    session.destroy
    
    render json: {
      success: true,
      message: 'Session deleted successfully'
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Session not found'
    }, status: :not_found
  end

  # GET /api/game_sessions
  # List all sessions for current user
  def index
    sessions = current_user.game_sessions.order(started_at: :desc)
    
    # Filter by status if provided
    sessions = sessions.where(status: params[:status]) if params[:status].present?
    
    render json: {
      success: true,
      sessions: sessions.map { |s| session_json(s) }
    }
  end

  private

  def session_params
    params.require(:game_session).permit(:puzzle_id, :status, game_state: {})
  end

  def session_json(session)
    {
      id: session.id.to_s,
      user_id: session.user_id.to_s,
      puzzle_id: session.puzzle_id.to_s,
      status: session.status,
      game_state: session.game_state || {},
      started_at: session.started_at.iso8601,
      completed_at: session.completed_at&.iso8601,
      created_at: session.created_at.iso8601,
      updated_at: session.updated_at.iso8601
    }
  end
end

