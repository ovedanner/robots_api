FactoryBot.define do
  factory :game do
    room { nil }
    current_winner { nil }
    board { nil }
    robot_positions { [] }
    completed_goals { [] }
    current_goal { {} }
  end
end
