class Api::HealthController < ApplicationController
  skip_before_action :authenticate_api_user!

  # GET /api/health
  def show
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      version: '1.0.0'
    }
  end
end
