class Api::UsersController < ApplicationController
  before_action :authenticate_api_user!
  skip_before_action :verify_authenticity_token

  # GET /api/users/profile
  def profile
    user = current_user
    
    # Calculate stats
    # Count distinct puzzles that have been completed
    puzzles_completed = user.game_sessions.completed.select(:puzzle_id).distinct.count
    active_sessions = user.game_sessions.active.count
    
    # Calculate current streak using updated_at from game sessions
    streak = calculate_streak(user)
    
    render json: {
      success: true,
      user: user_json(user),
      stats: {
        puzzles_completed: puzzles_completed,
        active_sessions: active_sessions,
        current_streak: streak
      }
    }
  end

  # GET /api/users/stats
  # Get user's game completion stats with percentiles
  def stats
    user = current_user
    
    # Get all completed sessions with puzzle info
    completed_sessions = user.game_sessions.completed
                             .where.not(completed_at: nil)
                             .includes(:puzzle)
    
    # Build game stats with percentiles
    game_stats = []
    completed_sessions.each do |session|
      next unless session.puzzle
      
      puzzle = session.puzzle
      user_score = session.game_state&.dig('final_score') || session.game_state&.dig('score') || 0
      
      # Skip if score is 0 (likely revealed)
      next if user_score == 0
      
      # Get all completed sessions for this puzzle to calculate percentile
      all_completed = GameSession.where(puzzle: puzzle, status: 'completed')
                                 .where.not(completed_at: nil)
      
      scores = []
      all_completed.each do |s|
        score = s.game_state&.dig('final_score') || s.game_state&.dig('score') || 0
        scores << score if score > 0
      end
      
      # Calculate percentile
      percentile = nil
      if scores.any? && user_score > 0
        worse_scores = scores.count { |s| s < user_score }
        percentile = ((worse_scores.to_f / scores.length) * 100).round(1)
      end
      
      game_stats << {
        puzzle_id: puzzle.id.to_s,
        puzzle_title: puzzle.puzzle_data&.dig('puzzle_clue') || puzzle.title || "Puzzle #{puzzle.id}",
        game_type: puzzle.game_type,
        challenge_date: puzzle.challenge_date,
        score: user_score,
        percentile: percentile,
        total_participants: scores.length
      }
    end
    
    # Sort by challenge_date desc (most recent first), then by puzzle_id
    game_stats.sort_by! { |g| [g[:challenge_date] || '', g[:puzzle_id]] }.reverse!
    
    render json: {
      success: true,
      total_games_completed: game_stats.length,
      games: game_stats
    }
  end

  # PUT /api/users/profile
  # Update user profile information
  def update_profile
    user = current_user
    
    if user.update(profile_params)
      render json: {
        success: true,
        user: user_json(user),
        message: 'Profile updated successfully'
      }
    else
      render json: {
        success: false,
        error: 'Failed to update profile',
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def calculate_streak(user)
    # Get all game sessions (completed or active), ordered by updated_at
    # Using updated_at to track when user last played
    sessions = user.game_sessions
                   .where.not(updated_at: nil)
                   .order(updated_at: :desc)
    
    return 0 if sessions.empty?
    
    # Group by date (ignoring time) using updated_at
    dates = sessions.map { |s| s.updated_at.to_date }.uniq.sort.reverse
    
    return 0 if dates.empty?
    
    # Check if most recent activity was today or yesterday
    today = Date.current
    yesterday = today - 1.day
    
    return 0 unless dates.first == today || dates.first == yesterday
    
    # Count consecutive days starting from most recent
    streak = 1
    current_date = dates.first
    
    dates[1..-1].each do |date|
      if date == current_date - 1.day
        streak += 1
        current_date = date
      else
        break
      end
    end
    
    streak
  end
end

