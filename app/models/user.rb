# User model
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true,
                    allow_blank: false,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true
  validates :firstname, presence: true, allow_blank: false
  validates :password, presence: true,
                       length: { minimum: 8 }
  validates :password, format: { with: /[A-Z]/ }
  validates :password, format: { with: /[0-9]/ }
end
