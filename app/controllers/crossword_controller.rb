class CrosswordController < ApplicationController
  before_action :authenticate_user!, except: [:show, :preview, :generate_layout]
  before_action :check_ai_availability, only: [:generate_ai]
  skip_before_action :verify_authenticity_token, only: [:generate_layout]
  
  # Ensure JSON responses for API-like endpoints
  respond_to :json

  # GET /crossword/generate_ai
  def generate_ai
    crossword_service = CrosswordGeneratorService.new
    result = crossword_service.generate_ai_puzzle(puzzle_params)
    
    if result[:success]
      render json: {
        success: true,
        puzzle: puzzle_json(result[:puzzle]),
        layout: result[:layout],
        message: 'AI puzzle generated successfully!'
      }, status: :created
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  # POST /crossword/generate_layout
  def generate_layout
    Rails.logger.info "generate_layout called with params: #{params.inspect}"
    
    begin
      words = layout_params[:words] || layout_params['words'] || []
      Rails.logger.info "Extracted words: #{words.inspect}"
      
      if words.empty?
        Rails.logger.error "No words provided for layout generation"
        render json: {
          success: false,
          error: 'No words provided for layout generation'
        }, status: :unprocessable_entity
        return
      end
      
      crossword_service = CrosswordGeneratorService.new
      layout = crossword_service.generate_layout(words, smart_order: true)
      
      # Warn if layout exceeds 15x15
      unless crossword_service.fits_15x15?(layout)
        Rails.logger.warn "Generated layout #{layout[:rows]}x#{layout[:cols]} exceeds 15x15 constraint"
      end
      
      render json: {
        success: true,
        layout: layout
      }
    rescue ActionController::ParameterMissing => e
      Rails.logger.error "Parameter error in generate_layout: #{e.message}"
      Rails.logger.error "Params received: #{params.inspect}"
      render json: {
        success: false,
        error: "Missing required parameter: #{e.param}"
      }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Error generating layout: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # GET /crossword/:id
  def show
    puzzle = Puzzle.find(params[:id])
    crossword_service = CrosswordGeneratorService.new
    layout = crossword_service.generate_layout(puzzle.clues, smart_order: true)
    
    # Warn if layout exceeds 15x15
    unless crossword_service.fits_15x15?(layout)
      Rails.logger.warn "Puzzle #{puzzle.id} layout #{layout[:rows]}x#{layout[:cols]} exceeds 15x15 constraint"
    end
    
    render json: {
      success: true,
      puzzle: puzzle_json(puzzle),
      layout: layout
    }
  end

  # GET /crossword/:id/preview
  def preview
    puzzle = Puzzle.find(params[:id])
    crossword_service = CrosswordGeneratorService.new
    layout = crossword_service.generate_layout(puzzle.clues, smart_order: true)
    
    # Warn if layout exceeds 15x15
    unless crossword_service.fits_15x15?(layout)
      Rails.logger.warn "Puzzle #{puzzle.id} preview layout #{layout[:rows]}x#{layout[:cols]} exceeds 15x15 constraint"
    end
    
    render json: {
      success: true,
      puzzle: puzzle_json(puzzle),
      layout: layout
    }
  end

  private

  def puzzle_params
    params.require(:puzzle).permit(:prompt, :difficulty, :theme, :word_count)
  end

  def layout_params
    # Handle both wrapped and unwrapped params
    if params[:layout].present?
      params.require(:layout).permit(words: [:clue, :answer])
    else
      # Fallback: assume words are at top level
      params.permit(words: [:clue, :answer])
    end
  end

  def check_ai_availability
    unless AiGeneratorService.available?
      render json: {
        success: false,
        error: 'AI puzzle generation is not available. Please contact support.'
      }, status: :service_unavailable
    end
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
      game_type: puzzle.game_type,
      type: puzzle.type,
      is_featured: puzzle.is_featured,
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
