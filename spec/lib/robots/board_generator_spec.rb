require 'rails_helper'

RSpec.describe Robots::BoardGenerator do
  describe 'generate' do
    it 'generates a proper new board' do
      board = described_class.generate
      cells = board.parsed_cells
      goals = board.parsed_goals
      robot_colors = board.parsed_robot_colors

      expect(cells.length).to eq(16)
      cells.each do |row|
        expect(row.length).to eq(16)
      end
      expect(goals.length).to eq(17)
      expect(robot_colors).to match_array(%w[red green yellow blue grey])
    end
  end
end
