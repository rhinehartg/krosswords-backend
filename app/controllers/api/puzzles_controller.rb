class Api::PuzzlesController < ApplicationController
  skip_before_action :authenticate_api_user!, only: [:index, :show]

  # GET /api/puzzles
  def index
    puzzles = Puzzle.where(is_published: true).order(created_at: :desc)
    
    # Filter for active challenges if requested
    if params[:type] == 'DailyChallenge' || params[:active_challenges] == 'true'
      today = Date.today
      week_start = today.beginning_of_week
      
      # Get daily challenges for today (Konundrum, KrissKross)
      daily_puzzles = puzzles.where(challenge_date: today, game_type: ['konundrum', 'krisskross'])
      
      # Get weekly challenges for current week (Krossword)
      weekly_puzzles = puzzles.where(challenge_date: week_start..week_start + 6.days, game_type: 'krossword')
      
      puzzles = daily_puzzles.or(weekly_puzzles)
    end
    
    # Apply filters
    puzzles = puzzles.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    puzzles = puzzles.where(game_type: params[:game_type]) if params[:game_type].present?
    # Filter by theme/clue in puzzle_data for new puzzle types, or description for legacy
    if params[:theme].present?
      puzzles = puzzles.where(
        "title ILIKE ? OR description ILIKE ? OR puzzle_data::text ILIKE ?",
        "%#{params[:theme]}%", "%#{params[:theme]}%", "%#{params[:theme]}%"
      )
    end
    
    # Get total count before pagination
    total_count = puzzles.count
    
    # Apply pagination
    offset = params[:offset].to_i if params[:offset].present?
    limit = params[:limit].to_i if params[:limit].present?
    puzzles = puzzles.offset(offset) if offset.present? && offset > 0
    puzzles = puzzles.limit(limit) if limit.present?
    
    # Get the actual count of puzzles returned
    puzzles_array = puzzles.to_a
    puzzles_count = puzzles_array.length
    
    # Calculate has_more: true if current offset + returned count is less than total
    has_more = limit.present? && (offset.to_i + puzzles_count < total_count)
    
    render json: {
      success: true,
      puzzles: puzzles_array.map { |puzzle| puzzle_json(puzzle) },
      total: total_count,
      offset: offset || 0,
      limit: limit || puzzles_count,
      has_more: has_more
    }
  end

  # GET /api/puzzles/:id
  def show
    puzzle = Puzzle.find(params[:id])
    
    render json: {
      success: true,
      puzzle: puzzle_json(puzzle)
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: 'Puzzle not found'
    }, status: :not_found
  end

  # POST /api/puzzles
  def create
    puzzle = Puzzle.new(puzzle_params)
    
    if puzzle.save
      render json: {
        success: true,
        puzzle: puzzle_json(puzzle),
        message: 'Puzzle created successfully'
      }, status: :created
    else
      render json: {
        success: false,
        error: 'Failed to create puzzle',
        errors: puzzle.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/puzzles/:id
  def update
    puzzle = Puzzle.find(params[:id])
    
    if puzzle.update(puzzle_params)
      render json: {
        success: true,
        puzzle: puzzle_json(puzzle),
        message: 'Puzzle updated successfully'
      }
    else
      render json: {
        success: false,
        error: 'Failed to update puzzle',
        errors: puzzle.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/puzzles/:id
  def destroy
    puzzle = Puzzle.find(params[:id])
    
    puzzle.destroy
    
    render json: {
      success: true,
      message: 'Puzzle deleted successfully'
    }
  end

  private

  def puzzle_params
    params.require(:puzzle).permit(
      :title, 
      :description, 
      :difficulty, 
      :clues, 
      :is_published,
      :game_type,
      puzzle_data: {}
    )
  end

  def puzzle_json(puzzle)
    base_json = {
      id: puzzle.id.to_s,
      title: puzzle.title,
      difficulty: puzzle.difficulty,
      rating: puzzle.average_rating.round,
      rating_count: puzzle.rating_count,
      is_published: puzzle.is_published,
      created_at: puzzle.created_at.iso8601,
      updated_at: puzzle.updated_at.iso8601,
      # Categorization fields
      type: puzzle.type,
      is_featured: puzzle.is_featured,
      challenge_date: puzzle.challenge_date&.iso8601,
      game_type: puzzle.game_type
    }
    
    # Add game-type-specific fields based on game_type
    case puzzle.game_type
    when 'krossword', nil
      # Legacy krossword or new krossword
      base_json.merge({
        description: puzzle.description,
        clues: parse_clues(puzzle.clues),
        puzzle_data: puzzle.puzzle_data
      })
    when 'konundrum'
      # Konundrum puzzle - use puzzle_data
      base_json.merge({
        puzzle_data: puzzle.puzzle_data,
        clue: puzzle.clue,
        words: puzzle.words,
        letters: puzzle.letters,
        seed: puzzle.seed
      })
    when 'krisskross'
      # KrissKross puzzle - use puzzle_data
      base_json.merge({
        puzzle_data: puzzle.puzzle_data,
        clue: puzzle.clue,
        words: puzzle.krisskross_words,
        layout: puzzle.krisskross_layout
      })
    else
      # Fallback for any puzzle
      base_json.merge({
        description: puzzle.description,
        clues: parse_clues(puzzle.clues),
        puzzle_data: puzzle.puzzle_data
      })
    end
  end

  def parse_clues(clues)
    return [] if clues.blank?
    
    if clues.is_a?(String)
      begin
        # Try JSON first
        JSON.parse(clues)
      rescue JSON::ParserError
        begin
          # Fall back to Ruby hash format
          eval(clues)
        rescue => e
          Rails.logger.error "Failed to parse clues: #{e.message}"
          []
        end
      end
    elsif clues.is_a?(Array)
      clues
    else
      []
    end
  end
end
