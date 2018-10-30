FactoryBot.define do
  factory :room do
    name { Faker::Simpsons.character }
    open { false }
    association :owner, factory: :user
  end
end
