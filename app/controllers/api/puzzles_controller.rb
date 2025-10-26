class Api::PuzzlesController < ApplicationController
  skip_before_action :authenticate_api_user!, only: [:index, :show]

  # GET /api/puzzles
  def index
    puzzles = Puzzle.where(is_published: true).order(created_at: :desc)
    
    # Apply filters
    puzzles = puzzles.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    puzzles = puzzles.where("title ILIKE ? OR description ILIKE ?", "%#{params[:theme]}%", "%#{params[:theme]}%") if params[:theme].present?
    puzzles = puzzles.limit(params[:limit].to_i) if params[:limit].present?
    
    render json: {
      success: true,
      puzzles: puzzles.map { |puzzle| puzzle_json(puzzle) }
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
    params.require(:puzzle).permit(:title, :description, :difficulty, :clues, :is_published)
  end

  def puzzle_json(puzzle)
    {
      id: puzzle.id,
      title: puzzle.title,
      description: puzzle.description,
      difficulty: puzzle.difficulty,
      rating: puzzle.average_rating,
      rating_count: puzzle.rating_count,
      clues: parse_clues(puzzle.clues),
      is_published: puzzle.is_published,
      created_at: puzzle.created_at,
      updated_at: puzzle.updated_at,
      # Categorization fields
      type: puzzle.type,
      is_featured: puzzle.is_featured,
      challenge_date: puzzle.challenge_date
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
