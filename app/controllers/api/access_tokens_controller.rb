module Api
  class AccessTokensController < ApiController
    skip_before_action :require_authentication

    # Creates a new access token if the credentials are valid.
    def create
      email, password = access_token_params
      authenticated = AuthenticateUser.call(email, password)
      if authenticated.success?
        token = AccessToken.create(user: authenticated.result)
        render json: token, status: :created if token
      else
        render(json: {}, status: :unauthorized)
      end
    end

    def access_token_params
      params.require(%i[email password])
    end
  end
end
