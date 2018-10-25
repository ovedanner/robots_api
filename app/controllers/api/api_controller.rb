module Api
  # Base controller for all API controllers.
  class ApiController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :require_authentication

    def require_authentication
      authenticate_token || render(json: {}, status: :unauthorized)
    end

    def current_user
      @current_user ||= authenticate_token
    end

    private

    # Validates the authentication token and retrieves the user.
    def authenticate_token
      authenticate_with_http_token do |token|
        t = AccessToken.with_unexpired_token(token)
        t&.user
      end
    end
  end
end
