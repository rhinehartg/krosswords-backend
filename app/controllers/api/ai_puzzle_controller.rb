class Api::AiPuzzleController < ApplicationController
  # Authentication is already handled by ApplicationController via JwtAuthentication
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
    puts "=== AI PUZZLE CONTROLLER: CREATE ACTION CALLED ==="
    puts "Params: #{params.inspect}"
    puts "Current user: #{current_user&.email}"
    
    Rails.logger.info "AI Puzzle Controller: create action called"
    Rails.logger.info "AI Puzzle Controller: params = #{params.inspect}"
    Rails.logger.info "AI Puzzle Controller: current_user = #{current_user&.email}"
    
    result = AiGeneratorService.new.generate_puzzle(puzzle_params)
    
    puts "AI Generator result: #{result.inspect}"
    Rails.logger.info "AI Puzzle Controller: result = #{result.inspect}"
    
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
    puts "=== PUZZLE_PARAMS CALLED ==="
    puts "Params: #{params.inspect}"
    puts "ai_puzzle param: #{params[:ai_puzzle].inspect}"
    
    Rails.logger.info "AI Puzzle Controller: puzzle_params called"
    Rails.logger.info "AI Puzzle Controller: params = #{params.inspect}"
    Rails.logger.info "AI Puzzle Controller: params[:ai_puzzle] = #{params[:ai_puzzle].inspect}"
    
    result = params.require(:ai_puzzle).permit(:prompt, :difficulty, :theme, :word_count)
    puts "Puzzle params result: #{result.inspect}"
    Rails.logger.info "AI Puzzle Controller: puzzle_params result = #{result.inspect}"
    result
  end

  def check_ai_availability
    Rails.logger.info "AI Puzzle Controller: check_ai_availability called"
    Rails.logger.info "AI Puzzle Controller: AiGeneratorService.available? = #{AiGeneratorService.available?}"
    
    unless AiGeneratorService.available?
      Rails.logger.error "AI Puzzle Controller: AI not available"
      render json: {
        success: false,
        error: 'AI puzzle generation is not available. Please contact support.'
      }, status: :service_unavailable
    end
  end

  def check_user_quota
    Rails.logger.info "AI Puzzle Controller: check_user_quota called"
    
    # For now, default to FREE tier since user tiers aren't implemented yet
    user_tier = 'FREE'
    Rails.logger.info "AI Puzzle Controller: user_tier = #{user_tier}"
    Rails.logger.info "AI Puzzle Controller: AiGeneratorService.has_quota?(#{user_tier}) = #{AiGeneratorService.has_quota?(user_tier)}"
    
    unless AiGeneratorService.has_quota?(user_tier)
      Rails.logger.error "AI Puzzle Controller: User quota exceeded"
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
