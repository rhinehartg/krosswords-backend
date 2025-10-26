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
    service = CrosswordGeneratorService.new
    service.generate_layout(@puzzle.clues)
  rescue => e
    Rails.logger.error "Crossword generation failed: #{e.message}"
    # Return a fallback layout
    {
      rows: 10,
      cols: 10,
      table: Array.new(10) { Array.new(10, '') },
      result: []
    }
  end
end
