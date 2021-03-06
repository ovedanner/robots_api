# User model
class User < ApplicationRecord
  # We want to be able to create a user without a password.
  # This happens when the user is created through another
  # identity provider.
  has_secure_password validations: false

  has_many :room_users
  has_many :access_tokens

  validates :email, presence: true,
                    allow_blank: false,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true
  validates :firstname, presence: true, allow_blank: false
  validates :password, presence: false, password: true

  after_create do
    UserMailer.with(user: self).welcome_email.deliver_later
  end

  # Determines if the user is a member of the given room.
  def member_of_room?(room)
    RoomUser.exists?(room_id: room.id, user_id: id)
  end
end
