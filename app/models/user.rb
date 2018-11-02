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

  # Determines if the user is a member of the given room.
  def is_member_of_room?(room)
    room.open && RoomUser.exists?(room_id: room.id, user_id: id)
  end

  # Uses the given Google info to either create a new user
  # or find an existing one.
  def self.find_or_create_from_google(google_info)
    email = google_info&.emails&.first&.value
    find_or_create_by(email: email) do |user|
      user.firstname = google_info.display_name.split(' ')[0]
    end
  end
end
