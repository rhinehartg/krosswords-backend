class AiPuzzleController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :create]
  before_action :check_ai_availability, only: [:create]
  before_action :check_user_quota, only: [:create]

  # GET /ai_puzzle
  def index
    render json: {
      available: AiGeneratorService.available?,
      quotas: AiGeneratorService::QUOTAS
    }
  end

  # POST /ai_puzzle
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

  # GET /ai_puzzle/:id
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
    # Admin users get unlimited access
    if admin_user_signed_in?
      Rails.logger.info "AI Generator: Admin user detected - unlimited access granted"
      return # Admin users have unlimited access
    end
    
    # For regular users, check quota
    user_tier = current_user&.tier || 'FREE'
    
    unless AiGeneratorService.has_quota?(user_tier)
      render json: {
        success: false,
        error: "You have reached your daily limit for AI puzzle generation. Upgrade to generate more puzzles."
      }, status: :too_many_requests
    end
  end

  private

  def admin_user_signed_in?
    # Check if we're coming from an admin page (referer check)
    referer = request.referer
    if referer&.include?('/admin')
      Rails.logger.info "AI Generator: Admin context detected via referer: #{referer}"
      return true
    end
    
    # Check if we have admin session
    if session[:admin_user_id].present?
      Rails.logger.info "AI Generator: Admin session detected"
      return true
    end
    
    # Check if we're in admin namespace
    if request.path.start_with?('/admin')
      Rails.logger.info "AI Generator: Admin path detected: #{request.path}"
      return true
    end
    
    Rails.logger.info "AI Generator: No admin context detected"
    false
  end

  def puzzle_json(puzzle)
    base_json = {
      id: puzzle.id.to_s,
      difficulty: puzzle.difficulty,
      rating: puzzle.average_rating.round,
      rating_count: puzzle.rating_count,
      is_published: puzzle.is_published,
      created_at: puzzle.created_at.iso8601,
      updated_at: puzzle.updated_at.iso8601,
      game_type: puzzle.game_type,
      type: puzzle.type,
      challenge_date: puzzle.challenge_date&.iso8601
    }
    
    # Add game-type-specific fields based on game_type
    case puzzle.game_type
    when 'krossword', nil
      base_json.merge({
        description: puzzle.description,
        clues: puzzle.clues.is_a?(Array) ? puzzle.clues : (puzzle.clues.present? ? JSON.parse(puzzle.clues) : []),
        puzzle_data: puzzle.puzzle_data
      })
    when 'konundrum'
      base_json.merge({
        puzzle_data: puzzle.puzzle_data,
        clue: puzzle.clue,
        words: puzzle.words,
        letters: puzzle.letters,
        seed: puzzle.seed
      })
    when 'krisskross'
      base_json.merge({
        puzzle_data: puzzle.puzzle_data,
        clue: puzzle.clue,
        words: puzzle.krisskross_words,
        layout: puzzle.krisskross_layout
      })
    else
      # Fallback for legacy puzzles
      base_json.merge({
        description: puzzle.description,
        clues: puzzle.clues.is_a?(Array) ? puzzle.clues : (puzzle.clues.present? ? JSON.parse(puzzle.clues) : []),
        puzzle_data: puzzle.puzzle_data
      })
    end
  end
end
