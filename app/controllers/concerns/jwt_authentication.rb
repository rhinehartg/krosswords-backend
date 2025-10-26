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
    Rails.logger.info "JWT Authentication: authenticate_api_user! called"
    token = extract_token_from_header
    Rails.logger.info "JWT Authentication: token extracted = #{token ? 'present' : 'missing'}"
    
    if token
      begin
        Rails.logger.info "JWT Authentication: attempting to decode token"
        decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
        user_id = decoded_token[0]['user_id']
        Rails.logger.info "JWT Authentication: user_id = #{user_id}"
        @current_user = User.find(user_id)
        Rails.logger.info "JWT Authentication: current_user found = #{@current_user.email}"
      rescue JWT::DecodeError => e
        Rails.logger.error "JWT Authentication: DecodeError - #{e.message}"
        render json: {
          success: false,
          error: 'Invalid or expired token'
        }, status: :unauthorized
      rescue JWT::ExpiredSignature => e
        Rails.logger.error "JWT Authentication: ExpiredSignature - #{e.message}"
        render json: {
          success: false,
          error: 'Invalid or expired token'
        }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "JWT Authentication: RecordNotFound - #{e.message}"
        render json: {
          success: false,
          error: 'Invalid or expired token'
        }, status: :unauthorized
      end
    else
      Rails.logger.error "JWT Authentication: No token provided"
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
