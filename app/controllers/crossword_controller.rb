class CrosswordController < ApplicationController
  before_action :authenticate_user!, except: [:show, :preview]
  before_action :check_ai_availability, only: [:generate_ai]

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
    crossword_service = CrosswordGeneratorService.new
    layout = crossword_service.generate_layout(layout_params[:words])
    
    render json: {
      success: true,
      layout: layout
    }
  rescue StandardError => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  end

  # GET /crossword/:id
  def show
    puzzle = Puzzle.find(params[:id])
    crossword_service = CrosswordGeneratorService.new
    layout = crossword_service.generate_layout(puzzle.clues)
    
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
    layout = crossword_service.generate_layout(puzzle.clues)
    
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
    params.require(:layout).permit(words: [:clue, :answer])
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
