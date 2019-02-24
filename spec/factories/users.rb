# User factory
FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "someguy#{n}@test.com"
    end
    password { 'Test1234' }
    firstname { Faker::Name.first_name }

    transient do
      room {}
      ready { true }
    end

    factory :user_with_access_token do
      after :create do |user|
        FactoryBot.create(:access_token, user: user)
      end
    end

    factory :user_in_room do
      after :create do |user, evaluator|
        FactoryBot.create(:room_user, room_id: evaluator.room.id, user_id: user.id, ready: evaluator.ready)
      end
    end
  end
end
