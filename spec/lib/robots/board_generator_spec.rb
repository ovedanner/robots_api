require 'rails_helper'

RSpec.describe Robots::BoardGenerator do
  describe 'generate' do
    it 'generates a proper new board' do
      # Generate multiple times to account for
      # the fact that the generator generates random
      # boards.
      hashes = []
      50.times do
        board = described_class.generate
        cells = board.parsed_cells
        goals = board.parsed_goals
        robot_colors = board.parsed_robot_colors
        data = {
          cells: cells,
          goals: goals,
          robot_colors: robot_colors
        }
        assert_valid_board_data(data)
        hashes << Digest::MD5.hexdigest(data.to_json)
      end

      # It's relatively unlikely that running the generator
      # 50 times yields the same 50 boards unless there is
      # something wrong with the generator logic.
      expect(hashes.uniq.length).to be > 1
    end
  end
end
