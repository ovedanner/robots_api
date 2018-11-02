# User factory
FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "someguy#{n}@test.com"
    end
    password { 'Test1234' }
    firstname { Faker::Name.first_name }

    factory :user_with_access_token do
      after :create do |user|
        FactoryBot.create(:access_token, user: user)
      end
    end
  end
end
