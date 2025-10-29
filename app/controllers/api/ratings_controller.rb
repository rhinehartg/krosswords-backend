class Api::RatingsController < ApplicationController
  before_action :authenticate_api_user!

  # POST /api/ratings
  def create
    # Find existing rating or create new one
    rating = Rating.find_or_initialize_by(
      user: current_user,
      puzzle_id: rating_params[:puzzle_id]
    )
    
    # Update the rating value
    rating.rating = rating_params[:rating]

    if rating.save
      message = rating.persisted? ? 'Rating updated successfully' : 'Rating submitted successfully'
      render json: {
        success: true,
        rating: rating_json(rating),
        message: message
      }, status: :created
    else
      render json: {
        success: false,
        error: 'Failed to submit rating',
        errors: rating.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/ratings/:id
  def update
    rating = Rating.find(params[:id])
    
    # Ensure user can only update their own rating
    if rating.user != current_user
      render json: {
        success: false,
        error: 'Not authorized to update this rating'
      }, status: :forbidden
      return
    end

    if rating.update(rating_params)
      render json: {
        success: true,
        rating: rating_json(rating),
        message: 'Rating updated successfully'
      }
    else
      render json: {
        success: false,
        error: 'Failed to update rating',
        errors: rating.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/ratings/:id
  def destroy
    rating = Rating.find(params[:id])
    
    # Ensure user can only delete their own rating
    if rating.user != current_user
      render json: {
        success: false,
        error: 'Not authorized to delete this rating'
      }, status: :forbidden
      return
    end

    rating.destroy
    
    render json: {
      success: true,
      message: 'Rating deleted successfully'
    }
  end

  # GET /api/ratings/user/:user_id
  def user_ratings
    user = User.find(params[:user_id])
    
    # Only allow users to see their own ratings or public ratings
    if user != current_user
      render json: {
        success: false,
        error: 'Not authorized to view these ratings'
      }, status: :forbidden
      return
    end

    ratings = user.ratings.includes(:puzzle).order(created_at: :desc)
    
    render json: {
      success: true,
      ratings: ratings.map { |rating| rating_json(rating) }
    }
  end

  # GET /api/ratings/puzzle/:puzzle_id
  def puzzle_ratings
    puzzle = Puzzle.find(params[:puzzle_id])
    
    ratings = puzzle.ratings.includes(:user).order(created_at: :desc)
    
    render json: {
      success: true,
      ratings: ratings.map { |rating| rating_json(rating) }
    }
  end

  # GET /api/ratings/user/:user_id/puzzle/:puzzle_id
  def user_puzzle_rating
    user = User.find(params[:user_id])
    puzzle = Puzzle.find(params[:puzzle_id])
    
    # Only allow users to see their own rating
    if user != current_user
      render json: {
        success: false,
        error: 'Not authorized to view this rating'
      }, status: :forbidden
      return
    end

    rating = Rating.find_by(user: user, puzzle: puzzle)
    
    if rating
      render json: {
        success: true,
        rating: rating_json(rating),
        has_rated: true
      }
    else
      render json: {
        success: true,
        rating: nil,
        has_rated: false
      }
    end
  end

  private

  def rating_params
    params.require(:rating).permit(:puzzle_id, :rating)
  end

  def rating_json(rating)
    {
      id: rating.id,
      rating: rating.rating,
      puzzle_id: rating.puzzle_id,
      puzzle_title: rating.puzzle.title,
      user_id: rating.user_id,
      user_email: rating.user.email,
      created_at: rating.created_at,
      updated_at: rating.updated_at
    }
  end
end
