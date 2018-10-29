# Authenticates a user with a Google authorization code.
#
require 'signet/oauth_2/client'
require 'google/apis/plus_v1'

class AuthenticateUserWithGoogle
  prepend SimpleCommand

  attr_accessor :authorization_code

  def initialize(authorization_code)
    @authorization_code = authorization_code
  end

  def call()
    info = user_info.get_person('me')
    User.find_or_create_from_google(info)
  end

  private

  # Create a new Google plus client by passing it our OAuth client
  # with the authorization code.
  def user_info
    Google::Apis::PlusV1::PlusService.new.tap do |userinfo|
      userinfo.key = ENV['GOOGLE_KEY']
      userinfo.authorization = google_info
    end
  end

  # Create a new OAuth client with the authorization code.
  def google_info
    Signet::OAuth2::Client.new(
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
      client_id: ENV['GOOGLE_KEY'], client_secret: ENV['GOOGLE_SECRET'],
      scope: 'email profile', redirect_uri: 'http://localhost:4200/torii/redirect.html'
    ).tap do |client|
      client.code = @authorization_code
      client.fetch_access_token!
    end
  end
end
