class PuzzlePreviewController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_puzzle

  def show
    @crossword_layout = generate_crossword_layout
  end

  private

  def set_puzzle
    @puzzle = Puzzle.find(params[:id])
  end

  def generate_crossword_layout
    # For KrissKross puzzles, use the layout stored in puzzle_data
    if @puzzle.game_type == 'krisskross' && @puzzle.puzzle_data.present? && @puzzle.puzzle_data['layout'].present?
      stored_layout = @puzzle.puzzle_data['layout']
      
      # Convert string keys to symbol keys and handle nested structures
      layout = {
        rows: stored_layout['rows'] || stored_layout[:rows],
        cols: stored_layout['cols'] || stored_layout[:cols],
        table: stored_layout['table'] || stored_layout[:table] || [],
        result: (stored_layout['result'] || stored_layout[:result] || []).map do |word|
          {
            clue: word['clue'] || word[:clue] || '',
            answer: word['answer'] || word[:answer] || '',
            startx: word['startx'] || word[:startx],
            starty: word['starty'] || word[:starty],
            position: word['position'] || word[:position],
            orientation: (word['orientation'] || word[:orientation] || 'across').to_s
          }
        end
      }
      
      Rails.logger.info "Using stored layout for KrissKross puzzle #{@puzzle.id}"
      return layout
    end
    
    # For Krossword puzzles, generate layout from clues
    service = CrosswordGeneratorService.new
    layout = service.generate_layout(@puzzle.clues, smart_order: true)
    
    # Warn if layout exceeds 15x15
    unless service.fits_15x15?(layout)
      Rails.logger.warn "Puzzle #{@puzzle.id} preview layout #{layout[:rows]}x#{layout[:cols]} exceeds 15x15 constraint"
    end
    
    layout
  rescue => e
    Rails.logger.error "Crossword generation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Return a fallback layout
    {
      rows: 10,
      cols: 10,
      table: Array.new(10) { Array.new(10, '') },
      result: []
    }
  end
end
