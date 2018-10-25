# User factory
FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "someguy#{n}@test.com"
    end
    password { 'Test1234' }
    firstname { Faker::Name.first_name }
  end
end
