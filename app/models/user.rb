# User model
class User < ApplicationRecord
  has_secure_password

  has_many :room_user

  validates :email, presence: true,
                    allow_blank: false,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true
  validates :firstname, presence: true, allow_blank: false
  validates :password, presence: true, password: true

  # Uses the given Google info to either create a new user
  # or find an existing one.
  def self.find_or_create_from_google(google_info)
    email = google_info&.emails&.first&.value
    find_or_create_by(email: email) do |user|
      user.firstname = google_info.display_name.split(' ')[0]
    end
  end
end
