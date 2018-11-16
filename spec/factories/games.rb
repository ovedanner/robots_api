FactoryBot.define do
  factory :game do
    room { nil }
    current_winner { nil }
    board { nil }
    robot_positions { [].to_json }
    completed_goals { [].to_json }
    current_goal { {}.to_json }
  end
end
