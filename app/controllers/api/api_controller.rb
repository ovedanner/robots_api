module Api
  # Base controller for all API controllers.
  class ApiController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :require_authentication

    def require_authentication
      unauthorized unless current_user
    end

    def current_user
      @current_user ||= authenticate_token
    end

    private

    # Renders HTTP 200.
    def success(body = {}, options = {})
      resp = { json: body, status: 200 }.merge(options)
      render resp
    end

    # Renders HTTP 201.
    def created(resource = {})
      render json: resource, status: :created
    end

    # Renders HTTP 400.
    def bad_request
      render json: {}, status: :bad_request
    end

    # Renders HTTP 401.
    def unauthorized
      render json: {}, status: :unauthorized
    end

    # Renders HTTP 404.
    def not_found
      render json: {}, status: :not_found
    end

    # Renders validation errors for the given resource.
    def validation_errors(resource)
      render json: resource,
             status: 422,
             adapter: :json_api,
             serializer: ActiveModel::Serializer::ErrorSerializer
    end

    # Validates the authentication token and retrieves the user.
    def authenticate_token
      authenticate_with_http_token do |token|
        t = AccessToken.with_unexpired_token(token)
        t&.user
      end
    end
  end
end
