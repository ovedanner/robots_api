module Api
  # Access tokens controller
  class AccessTokensController < ApiController
    skip_before_action :require_authentication, only: %i[create create_with_google]

    # Creates a new access token if the credentials are valid.
    def create
      email, password = access_token_params
      render_authentication_result(
        AuthenticateUser.call(email, password)
      )
    end

    # Creates a new access token if the provided Google authorization code
    # is valid.
    def create_with_google
      render_authentication_result(
        AuthenticateUserWithGoogle.call(params.require(:code))
      )
    end

    # Deletes an access token.
    def destroy
      @token = AccessToken.find(params.require(:id))

      if @token
        @token.destroy
      else
        render json: {}, status: :not_found
      end
    end

    private

    def access_token_params
      params.require(%i[email password])
    end

    def render_authentication_result(command)
      if command.success?
        token = AccessToken.create(user: command.result)
        render json: token, status: :created if token
      else
        render(json: {}, status: :unauthorized)
      end
    end
  end
end
