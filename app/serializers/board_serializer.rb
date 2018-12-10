class BoardSerializer < ActiveModel::Serializer
  attributes :id

  attribute :cells do
    object.cells
  end

  attribute :goals do
    object.goals
  end

  attribute :robot_colors do
    object.robot_colors
  end
end
