require 'rails_helper'

RSpec.describe Robots::BoardGenerator do
  describe 'generate' do
    it 'generates a proper new board' do
      board = described_class.generate
      cells = board.cells
      goals = board.goals
      robot_colors = board.robot_colors

      expect(cells.length).to eq(16)
      cells.each do |row|
        expect(row.length).to eq(16)
      end
      expect(goals.length).to eq(17)
      expect(robot_colors).to match_array(%i[red green yellow blue grey])
    end

    context 'when called multiple times' do
      it 'initializes only once' do
        described_class.board_parts = nil

        expect(described_class).to receive(:initialize_parts)
          .and_return(described_class.initialize_parts)

        described_class.generate
        described_class.generate
      end
    end
  end
end
