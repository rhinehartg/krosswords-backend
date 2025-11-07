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
    
    # Store completion metadata in game_state
    completion_data = {}
    if session.started_at
      duration = Time.current - session.started_at
      completion_data[:completion_duration_seconds] = duration.to_i
    end
    
    # Store score if provided in game_state
    # If puzzle was revealed, score should be 0
    if session.game_state
      if session.game_state['isRevealed'] || session.game_state['wasRevealed']
        # Puzzle was revealed - set score to 0
        completion_data[:final_score] = 0
        completion_data[:was_revealed] = true
      elsif session.game_state['score']
        completion_data[:final_score] = session.game_state['score']
        completion_data[:was_revealed] = false
      end
    end
    
    # Update game_state with completion data
    if completion_data.any?
      session.update_game_state(completion_data)
    end
    
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

  # GET /api/game_sessions/:id/stats
  # Get completion stats for a puzzle (percentile ranking, etc.)
  def stats
    session = current_user.game_sessions.find(params[:id])
    
    unless session.completed?
      render json: {
        success: false,
        error: 'Session not completed'
      }, status: :unprocessable_entity
      return
    end
    
    puzzle = session.puzzle
    
    # Get all completed sessions for this puzzle
    all_completed = GameSession.where(puzzle: puzzle, status: 'completed')
                                .where.not(completed_at: nil)
    
    total_completions = all_completed.count
    
    if total_completions == 0
      render json: {
        success: true,
        stats: {
          total_completions: 0,
          user_percentile: nil,
          user_rank: nil,
          message: 'No other completions yet'
        }
      }
      return
    end
    
    # Calculate user's score (use duration as primary metric, score as secondary)
    user_duration = session.completed_at - session.started_at
    user_score = session.game_state&.dig('final_score') || session.game_state&.dig('score') || 0
    
    # Get all scores and durations
    scores = []
    durations = []
    
    all_completed.each do |s|
      if s.started_at && s.completed_at
        duration = s.completed_at - s.started_at
        durations << duration
      end
      
      score = s.game_state&.dig('final_score') || s.game_state&.dig('score') || 0
      scores << score
    end
    
    # Calculate percentile based on score (higher is better)
    # If score is 0 or not available, use duration (lower is better)
    if user_score > 0 && scores.any? { |s| s > 0 }
      # Rank by score (higher is better)
      # Percentile = percentage of players with LOWER scores
      worse_scores = scores.count { |s| s < user_score }
      user_percentile = ((worse_scores.to_f / total_completions) * 100).round(1)
      # Rank = number of players with higher or equal scores (1 = best)
      better_scores = scores.count { |s| s > user_score }
      user_rank = better_scores + 1
    elsif durations.any?
      # Rank by duration (lower is better)
      # Percentile = percentage of players with HIGHER (worse) times
      worse_times = durations.count { |d| d > user_duration }
      user_percentile = ((worse_times.to_f / total_completions) * 100).round(1)
      # Rank = number of players with lower (better) times + 1 (1 = best)
      better_times = durations.count { |d| d < user_duration }
      user_rank = better_times + 1
    else
      user_percentile = nil
      user_rank = nil
    end
    
    # Calculate distribution stats
    avg_score = scores.any? ? (scores.sum.to_f / scores.length).round(1) : nil
    avg_duration = durations.any? ? (durations.sum.to_f / durations.length).round(1) : nil
    
    render json: {
      success: true,
      stats: {
        total_completions: total_completions,
        user_percentile: user_percentile,
        user_rank: user_rank,
        user_score: user_score,
        user_duration_seconds: user_duration.to_i,
        average_score: avg_score,
        average_duration_seconds: avg_duration,
        message: user_percentile ? "You scored better than #{user_percentile}% of players!" : "Great job completing the puzzle!"
      }
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

  # GET /api/puzzles/:puzzle_id/leaderboard
  # Get user's stats for a specific puzzle (percentile based on score)
  def leaderboard
    puzzle = Puzzle.find(params[:puzzle_id])
    
    # Get all completed sessions for this puzzle
    completed_sessions = GameSession.where(puzzle: puzzle, status: 'completed')
                                    .where.not(completed_at: nil)
    
    total_completions = completed_sessions.count
    
    if total_completions == 0
      render json: {
        success: true,
        total_completions: 0,
        user_percentile: nil,
        user_score: nil,
        message: 'No completions yet'
      }
      return
    end
    
    # Get all scores for this puzzle
    scores = []
    completed_sessions.each do |session|
      score = session.game_state&.dig('final_score') || session.game_state&.dig('score') || 0
      scores << score if score > 0
    end
    
    # Get current user's session and score
    user_session = completed_sessions.find_by(user: current_user)
    user_score = nil
    user_percentile = nil
    
    if user_session
      user_score = user_session.game_state&.dig('final_score') || user_session.game_state&.dig('score') || 0
      
      if user_score > 0 && scores.any?
        # Calculate percentile: percentage of players with LOWER scores
        worse_scores = scores.count { |s| s < user_score }
        user_percentile = ((worse_scores.to_f / scores.length) * 100).round(1)
      end
    end
    
    render json: {
      success: true,
      total_completions: total_completions,
      user_percentile: user_percentile,
      user_score: user_score,
      message: user_percentile ? "You scored better than #{user_percentile}% of players!" : "Great job completing the puzzle!"
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Puzzle not found'
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

