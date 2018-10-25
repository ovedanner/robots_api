# Authenticates a user by email and password
#
class AuthenticateUser
  prepend SimpleCommand

  attr_accessor :email, :password

  def initialize(email, password)
    @email = email
    @password = password
  end

  def call()
    user = User.find_by_email(email)
    return user if user&.authenticate(password)

    errors.add :user_authentication, 'invalid credentials'
  end
end
