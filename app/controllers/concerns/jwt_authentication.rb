module JwtAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_user!, if: :api_request?
  end

  private

  def api_request?
    request.path.start_with?('/api/')
  end

  def authenticate_api_user!
    token = extract_token_from_header
    
    if token
      begin
        decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
        user_id = decoded_token[0]['user_id']
        @current_user = User.find(user_id)
      rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Invalid or expired token'
        }, status: :unauthorized
      end
    else
      render json: {
        success: false,
        error: 'Authorization token required'
      }, status: :unauthorized
    end
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')
    
    auth_header.split(' ').last
  end

  def current_user
    @current_user
  end
end
