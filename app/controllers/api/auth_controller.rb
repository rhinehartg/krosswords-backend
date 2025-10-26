class Api::AuthController < ApplicationController
  before_action :authenticate_api_user!, only: [:logout, :refresh, :me]
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_api_user!, only: [:login, :register]

  # POST /api/auth/login
  def login
    user = User.find_by(email: login_params[:email])
    
    if user && user.valid_password?(login_params[:password])
      token = generate_jwt_token(user)
      
      render json: {
        success: true,
        user: user_json(user),
        token: token,
        message: 'Login successful'
      }
    else
      render json: {
        success: false,
        error: 'Invalid email or password'
      }, status: :unauthorized
    end
  end

  # POST /api/auth/register
  def register
    user = User.new(register_params)
    
    if user.save
      token = generate_jwt_token(user)
      
      render json: {
        success: true,
        user: user_json(user),
        token: token,
        message: 'Registration successful'
      }, status: :created
    else
      render json: {
        success: false,
        error: 'Registration failed',
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/auth/logout
  def logout
    # For JWT tokens, logout is handled client-side by removing the token
    # But we can log the logout event for security purposes
    Rails.logger.info "User #{current_user.email} logged out"
    
    render json: {
      success: true,
      message: 'Logout successful'
    }
  end

  # POST /api/auth/refresh
  def refresh
    token = generate_jwt_token(current_user)
    
    render json: {
      success: true,
      token: token,
      message: 'Token refreshed successfully'
    }
  end

  # GET /api/auth/me
  def me
    render json: {
      success: true,
      user: user_json(current_user)
    }
  end

  private

  def login_params
    params.require(:auth).permit(:email, :password)
  end

  def register_params
    params.require(:auth).permit(:email, :password, :password_confirmation)
  end

  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: 24.hours.from_now.to_i
    }
    
    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
