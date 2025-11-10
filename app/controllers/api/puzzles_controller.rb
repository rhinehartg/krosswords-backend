class Api::PuzzlesController < ApplicationController
  skip_before_action :authenticate_api_user!, only: [:index, :show]

  # GET /api/puzzles
  def index
    # Get today's date (challenge_date is date-only, no timezone needed)
    today = Date.today
    
    # Order puzzles to prioritize: past (most recent first), then today, then future (nearest first)
    # This ensures past puzzles appear first in the list so they're visible to users
    puzzles = Puzzle.where(is_published: true)
      .order(
        Arel.sql("CASE 
          WHEN challenge_date < '#{today}' THEN 1 
          WHEN challenge_date = '#{today}' THEN 2 
          WHEN challenge_date > '#{today}' THEN 3 
          ELSE 4 
        END"),
        Arel.sql("CASE 
          WHEN challenge_date < '#{today}' THEN challenge_date END DESC"),
        Arel.sql("CASE 
          WHEN challenge_date > '#{today}' THEN challenge_date END ASC"),
        created_at: :desc
      )
    
    # Filter for active challenges if requested
    # Challenges use date ranges:
    # - Daily challenges (Konundrum, KrissKross, Konstructor): challenge_date represents a single day (must match today)
    # - Weekly challenges (Krossword): challenge_date must be on Sunday
    if params[:type] == 'DailyChallenge' || params[:active_challenges] == 'true'
      # Daily challenges: Konundrum, KrissKross, and Konstructor - match if challenge_date is today (exact match only)
      daily_puzzles = puzzles.where(challenge_date: today, game_type: ['konundrum', 'krisskross', 'konstructor'])
      
      # Weekly challenges: Krossword - match if challenge_date is the current/upcoming Sunday
      # Krosswords are available Monday-Sunday, with challenge_date set to Sunday
      # Show this week's Sunday krossword (available all week, including Sunday itself)
      if today.wday == 0
        # Today is Sunday, show THIS Sunday's krossword (today)
        sunday = today
      elsif today.wday == 6
        # Today is Saturday, show tomorrow's (next Sunday's) krossword
        sunday = today + 1.day
      else
        # Show the upcoming Sunday
        days_until_sunday = 7 - today.wday
        sunday = today + days_until_sunday.days
      end
      weekly_puzzles = puzzles.where(challenge_date: sunday, game_type: 'krossword')
      
      puzzles = daily_puzzles.or(weekly_puzzles)
    else
      # Past puzzles: only show puzzles with challenge_date in the past (before today)
      puzzles = puzzles.where("challenge_date < ?", today)
    end
    
    # Apply filters
    puzzles = puzzles.where(game_type: params[:game_type]) if params[:game_type].present?
    # Filter by theme/clue in puzzle_data for new puzzle types, or description for legacy
    if params[:theme].present?
      puzzles = puzzles.where(
        "description ILIKE ? OR puzzle_data::text ILIKE ?",
        "%#{params[:theme]}%", "%#{params[:theme]}%"
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
    
    # Use summary mode for list views (skip expensive operations like letters generation)
    summary_mode = params[:summary] == 'true' || params[:summary] == true
    
    render json: {
      success: true,
      puzzles: puzzles_array.map { |puzzle| puzzle_json(puzzle, summary: summary_mode) },
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
      :clues, 
      :is_published,
      :game_type,
      puzzle_data: {}
    )
  end

  def puzzle_json(puzzle, summary: false)
    base_json = {
      id: puzzle.id.to_s,
      is_published: puzzle.is_published,
      created_at: puzzle.created_at.iso8601,
      updated_at: puzzle.updated_at.iso8601,
      # Categorization fields
      type: puzzle.type,
      challenge_date: puzzle.challenge_date&.iso8601,
      game_type: puzzle.game_type,
      # Include title from puzzle_data if available
      title: puzzle.puzzle_data&.dig('title') || puzzle.description&.truncate(50)
    }
    
    # In summary mode, only include minimal data needed for list views
    return base_json if summary
    
    # Full data for game views - delegate to game-type-specific helpers
    case puzzle.game_type
    when 'krossword', nil
      base_json.merge(krossword_json(puzzle))
    when 'konundrum'
      base_json.merge(konundrum_json(puzzle))
    when 'krisskross'
      base_json.merge(krisskross_json(puzzle))
    when 'konstructor'
      base_json.merge(konstructor_json(puzzle))
    else
      # Fallback for any puzzle
      base_json.merge(krossword_json(puzzle)) # Default to krossword format
    end
  end
  
  # Helper for Krossword puzzle JSON
  def krossword_json(puzzle)
    {
      description: puzzle.description,
      clues: parse_clues(puzzle.clues),
      puzzle_data: puzzle.puzzle_data
    }
  end
  
  # Helper for Konundrum puzzle JSON
  def konundrum_json(puzzle)
    {
      puzzle_data: puzzle.puzzle_data,
      clue: puzzle.clue,
      words: puzzle.words,
      letters: puzzle.letters, # This will generate from seed if needed
      seed: puzzle.seed
    }
  end
  
  # Helper for KrissKross puzzle JSON
  def krisskross_json(puzzle)
    {
      puzzle_data: puzzle.puzzle_data,
      clue: puzzle.clue,
      words: puzzle.krisskross_words,
      layout: puzzle.krisskross_layout
    }
  end
  
  # Helper for Konstructor puzzle JSON
  def konstructor_json(puzzle)
    {
      puzzle_data: puzzle.puzzle_data,
      words: puzzle.konstructor_words
    }
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
