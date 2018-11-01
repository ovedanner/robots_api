module Api
  # Base controller for all API controllers.
  class ApiController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :require_authentication

    def require_authentication
      render(json: {}, status: :unauthorized) unless current_user
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

    # Renders validation errors for the given resource.
    def render_json_validation_error(resource)
      render json: resource,
             status: 422,
             adapter: :json_api,
             serializer: ActiveModel::Serializer::ErrorSerializer
    end
  end
end
