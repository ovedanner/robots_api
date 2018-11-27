class BoardSerializer < ActiveModel::Serializer
  attributes :id

  attribute :cells do
    object.parsed_cells
  end

  attribute :goals do
    object.parsed_goals
  end

  attribute :robot_colors do
    object.parsed_robot_colors
  end
end
