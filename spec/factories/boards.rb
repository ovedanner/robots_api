FactoryBot.define do
  factory :board do
    cells { [].to_json }
    goals { [].to_json }
    robot_colors { [].to_json }
  end
end
