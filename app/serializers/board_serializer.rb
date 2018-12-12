class BoardSerializer < ActiveModel::Serializer
  attributes :id, :cells, :goals, :robot_colors
end
