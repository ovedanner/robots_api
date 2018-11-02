FactoryBot.define do
  factory :room do
    name { Faker::Simpsons.character }
    open { false }
    association :owner, factory: :user

    transient do
      member {}
    end

    factory :open_room do
      open { true }
    end

    factory :closed_room do
      open { false }
    end

    factory :room_with_member do
      after :create do |room, evaluator|
        FactoryBot.create(:room_user, room_id: room.id, user_id: evaluator.member.id)
      end
    end
  end
end
