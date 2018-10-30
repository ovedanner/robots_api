# Access token model.
class AccessToken < ApplicationRecord
  has_secure_token
  belongs_to :user

  validates :user, presence: true
  validates :token, uniqueness: true

  # Set the token expiration date.
  before_save do
    self.expires_at = 1.day.from_now if expires_at.blank?
  end

  # Retrieves an AccessToken that matches the given token
  # and is not expired.
  def self.with_unexpired_token(token)
    where(token: token).where('expires_at > ?', Time.now).first
  end
end
