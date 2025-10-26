class Api::AiPuzzleController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :create]
  before_action :check_ai_availability, only: [:create]
  before_action :check_user_quota, only: [:create]

  # GET /api/ai_puzzle
  def index
    render json: {
      available: AiGeneratorService.available?,
      quotas: AiGeneratorService::QUOTAS
    }
  end

  # POST /api/ai_puzzle
  def create
    result = AiGeneratorService.new.generate_puzzle(puzzle_params)
    
    if result[:success]
      render json: {
        success: true,
        puzzle: puzzle_json(result[:puzzle]),
        message: 'Puzzle generated successfully!'
      }, status: :created
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  # GET /api/ai_puzzle/:id
  def show
    puzzle = Puzzle.find(params[:id])
    render json: {
      success: true,
      puzzle: puzzle_json(puzzle)
    }
  end

  private

  def puzzle_params
    params.require(:ai_puzzle).permit(:prompt, :difficulty, :theme, :word_count)
  end

  def check_ai_availability
    unless AiGeneratorService.available?
      render json: {
        success: false,
        error: 'AI puzzle generation is not available. Please contact support.'
      }, status: :service_unavailable
    end
  end

  def check_user_quota
    # For now, default to FREE tier since user tiers aren't implemented yet
    user_tier = 'FREE'
    
    unless AiGeneratorService.has_quota?(user_tier)
      render json: {
        success: false,
        error: "You have reached your daily limit for AI puzzle generation. Upgrade to generate more puzzles."
      }, status: :too_many_requests
    end
  end

  def puzzle_json(puzzle)
    {
      id: puzzle.id,
      title: puzzle.title,
      description: puzzle.description,
      difficulty: puzzle.difficulty,
      rating: puzzle.rating,
      clues: puzzle.clues,
      is_published: puzzle.is_published,
      created_at: puzzle.created_at,
      updated_at: puzzle.updated_at
    }
  end
end
