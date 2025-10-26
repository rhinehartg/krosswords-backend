class Api::PuzzlesController < ApplicationController
  before_action :authenticate_api_user!, except: [:index, :show]

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
    puzzle.user = current_user if current_user
    
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
    
    # Check if user owns the puzzle or is admin
    unless puzzle.user == current_user || current_user&.admin?
      render json: {
        success: false,
        error: 'Not authorized to update this puzzle'
      }, status: :forbidden
      return
    end
    
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
    
    # Check if user owns the puzzle or is admin
    unless puzzle.user == current_user || current_user&.admin?
      render json: {
        success: false,
        error: 'Not authorized to delete this puzzle'
      }, status: :forbidden
      return
    end
    
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
      clues: puzzle.clues,
      is_published: puzzle.is_published,
      created_at: puzzle.created_at,
      updated_at: puzzle.updated_at,
      user: puzzle.user ? {
        id: puzzle.user.id,
        email: puzzle.user.email
      } : nil
    }
  end
end
