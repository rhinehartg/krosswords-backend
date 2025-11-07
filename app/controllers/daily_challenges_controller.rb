class DailyChallengesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :create]
  
  def index
    render json: { 
      available: AiGeneratorService.available?,
      prompt_template: AiGeneratorService.current_prompt_template,
      using_custom_prompt: AiGeneratorService.using_custom_prompt?
    }
  end
  
  def show
    @daily_challenge = DailyChallenge.find(params[:id])
    render json: {
      success: true,
      daily_challenge: {
        id: @daily_challenge.id,
        title: @daily_challenge.title,
        description: @daily_challenge.description,
        difficulty: @daily_challenge.difficulty,
        rating: @daily_challenge.rating,
        clues: @daily_challenge.clues,
        challenge_date: @daily_challenge.challenge_date
      }
    }
  end
  
  def create
    begin
      # Validate required parameters
      challenge_params = params.require(:daily_challenge).permit(
        :challenge_date, :prompt, :difficulty, :word_count, 
        :title_override, :description_override
      )
      
      # Check if daily challenge already exists for this date
      existing_challenge = DailyChallenge.find_by(challenge_date: challenge_params[:challenge_date])
      if existing_challenge
        return render json: {
          success: false,
          error: "Daily challenge already exists for #{challenge_params[:challenge_date]}"
        }, status: :conflict
      end
      
      # Generate the puzzle using AI
      ai_service = AiGeneratorService.new
      result = ai_service.generate_puzzle({
        prompt: challenge_params[:prompt],
        difficulty: challenge_params[:difficulty],
        word_count: challenge_params[:word_count].to_i
      })
      
      if result[:success]
        puzzle = result[:puzzle]
        
        # Create daily challenge with overrides
        daily_challenge = DailyChallenge.create!(
          title: challenge_params[:title_override].presence || "#{puzzle.game_type || 'Puzzle'} - #{challenge_params[:challenge_date]}",
          description: challenge_params[:description_override].present? ? challenge_params[:description_override] : puzzle.description,
          difficulty: puzzle.difficulty,
          rating: puzzle.rating,
          clues: puzzle.clues,
          is_published: true,
          challenge_date: challenge_params[:challenge_date]
        )
        
        render json: {
          success: true,
          daily_challenge: {
            id: daily_challenge.id,
            title: daily_challenge.title,
            description: daily_challenge.description,
            difficulty: daily_challenge.difficulty,
            rating: daily_challenge.rating,
            clues_count: daily_challenge.clues.length,
            challenge_date: daily_challenge.challenge_date
          }
        }
      else
        render json: {
          success: false,
          error: result[:error] || "Failed to generate puzzle"
        }, status: :unprocessable_entity
      end
      
    rescue StandardError => e
      Rails.logger.error "Daily challenge generation error: #{e.message}"
      render json: {
        success: false,
        error: "An error occurred while generating the daily challenge: #{e.message}"
      }, status: :internal_server_error
    end
  end
  
  private
  
  def check_user_quota
    # Admin users have unlimited access
    return if admin_user_signed_in?
    
    # For regular users, implement quota checking here if needed
    # For now, we'll allow unlimited access
  end
  
  def admin_user_signed_in?
    # Check if request is coming from Active Admin
    return true if request.referer&.include?('/admin')
    return true if session[:admin_user_id].present?
    return true if request.path.start_with?('/admin')
    false
  end
end
