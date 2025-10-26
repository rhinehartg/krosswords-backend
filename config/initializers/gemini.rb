# AI Generator Configuration
Rails.application.configure do
  # Check for API key in environment variables or Rails credentials
  api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key
  
  if api_key.present?
    Rails.logger.info "Gemini API key configured. AI puzzle generation is available."
    Rails.logger.debug "API key source: #{ENV['GEMINI_API_KEY'].present? ? 'environment variable' : 'Rails credentials'}"
  else
    Rails.logger.warn "Gemini API key not configured. AI puzzle generation will not be available."
    Rails.logger.warn "Set your API key with either:"
    Rails.logger.warn "  - Environment variable: export GEMINI_API_KEY=your_key"
    Rails.logger.warn "  - Rails credentials: rails credentials:edit"
  end
end
