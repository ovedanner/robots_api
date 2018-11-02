# Access token factory
FactoryBot.define do
  factory :access_token do
    token { AccessToken.generate_unique_secure_token }
    user
  end
end
