module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    # Setup the current user. The current_user will be available to
    # the channels.
    def connect
      @current_user = authenticated_user
    end

    private

    # For now, a user is authenticated using an access token in the URL.
    # Should be ok as access tokens can be revoked (deleted).
    def authenticated_user
      token = request.params[:token]
      if token
        t = AccessToken.with_unexpired_token(token)
        t&.user
      else
        reject_unauthorized_connection
      end

    end
  end
end
