require "signet/oauth_2/client"

class AuthenticateUserWithGoogle
  prepend SimpleCommand

  attr_accessor :authorization_code

  def initialize(authorization_code)
    @authorization_code = authorization_code
  end

  def call
    client = Signet::OAuth2::Client.new(
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://www.googleapis.com/oauth2/v3/token",
      client_id: ENV["GOOGLE_KEY"], client_secret: ENV["GOOGLE_SECRET"],
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"]
    ).tap do |client|
      client.code = @authorization_code
      client.fetch_access_token!
    end

    id_token = client.id_token.split(".")[1]
    payload = JSON.parse(Base64.decode64(id_token))

    User.find_or_create_by(email: payload["email"])
  end
end
