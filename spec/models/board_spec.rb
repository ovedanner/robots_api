require 'rails_helper'

RSpec.describe Board, type: :model do
  describe '#cells' do
    let(:valid_cells) do
      <<~HEREDOC
        [[1,1,1],[2,2,2],[3,3,3]]
      HEREDOC
    end

    it { is_expected.to allow_value(nil).for(:cells) }
    it { is_expected.not_to allow_value('invalid JSON').for(:cells) }
    it { is_expected.not_to allow_value(4).for(:cells) }

    it { is_expected.to allow_value(valid_cells).for(:cells) }
  end

  describe '#goals' do
    let(:valid_goals) do
      <<~HEREDOC
        [{"number":2,"color":"red"}]
      HEREDOC
    end

    it { is_expected.to allow_value(nil).for(:goals) }
    it { is_expected.not_to allow_value('invalid JSON').for(:goals) }
    it { is_expected.not_to allow_value(4).for(:goals) }

    it { is_expected.to allow_value(valid_goals).for(:goals) }
  end

  describe '#robot_colors' do
    let(:valid_robot_colors) do
      <<~HEREDOC
        ["red", "blue"]
      HEREDOC
    end

    it { is_expected.to allow_value(nil).for(:robot_colors) }
    it { is_expected.not_to allow_value('invalid JSON').for(:robot_colors) }
    it { is_expected.not_to allow_value(4).for(:robot_colors) }

    it { is_expected.to allow_value(valid_robot_colors).for(:robot_colors) }
  end

  describe '#column_cells' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [1, 2, 3, 4],
          [5, 6, 7, 8],
          [9, 10, 11, 12],
          [13, 14, 15, 0]
        ].to_json, goals: [
          { number: 2, color: Board::RED }
        ].to_json, robot_colors: [Board::RED].to_json
      )
    end

    context 'when retrieving column cells' do
      it 'returns the proper array' do
        expected = [
          [1, 5, 9, 13],
          [2, 6, 10, 14],
          [3, 7, 11, 15],
          [4, 8, 12, 0]
        ]
        expect(board.column_cells).to match_array(expected)
      end
    end
  end

  describe '#random_goal' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [5, 1, 1, 3],
          [8, 0, 0, 2],
          [8, 0, 0, 2],
          [12, 4, 4, 14]
        ].to_json, goals: [
        { number: 2, color: Board::RED },
        { number: 6, color: Board::BLUE }
      ].to_json, robot_colors: [Board::RED, Board::BLUE].to_json
      )
    end

    context 'when called' do
      it 'returns a random goal' do
        goal = board.random_goal
        expect(goal[:number]).to be_in([2, 6])
        expect(goal[:color]).to be_in([Board::RED, Board::BLUE])
      end
    end
  end

  describe '#random_goal_not_in' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [5, 1, 1, 3],
          [8, 0, 0, 2],
          [8, 0, 0, 2],
          [12, 4, 4, 14]
        ].to_json, goals: [
        { number: 2, color: Board::RED },
        { number: 6, color: Board::BLUE }
      ].to_json, robot_colors: [Board::RED, Board::BLUE].to_json
      )
    end

    context 'when called with a goal' do
      it 'returns another goal' do
        goal = board.random_goal_not_in([{ number: 2, color: Board::RED }])
        expect(goal[:number]).to be(6)
        expect(goal[:color]).to eq(Board::BLUE)
      end
    end

    context 'when called with all goals' do
      it 'returns nothing' do
        given_goals = [
          { number: 2, color: Board::RED },
          { number: 6, color: Board::BLUE }
        ]
        expect(board.random_goal_not_in(given_goals)).to be_falsey
      end
    end
  end

  describe '#valid_move?' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [5, 1, 1, 3],
          [8, 0, 0, 2],
          [8, 0, 0, 2],
          [12, 4, 4, 14]
        ].to_json, goals: [
          { number: 2, color: Board::RED },
          { number: 6, color: Board::BLUE }
        ].to_json, robot_colors: [Board::RED, Board::BLUE].to_json
      )
    end

    let(:robot_positions) do
      [
        {robot: Board::RED, position: {row: 1, column: 1 } },
        {robot: Board::BLUE, position: {row: 3, column: 1 } }
      ]
    end

    context 'when valid up move' do
      let(:move) do
        {
          robot: Board::RED,
          to: {
            row: 0,
            column: 1
          }
        }
      end

      it 'returns true' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when diagonal up move' do
      let(:move) do
        {
          robot: Board::RED,
          to: {
            row: 0,
            column: 0
          }
        }
      end

      it 'returns false' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(false)
      end
    end

    context 'when valid down move' do
      let(:move) do
        {
          robot: Board::RED,
          to: {
            row: 2,
            column: 1
          }
        }
      end

      it 'returns true' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when diagonal down move' do
      let(:move) do
        {
          robot: Board::RED,
          to: {
            row: 2,
            column: 2
          }
        }
      end

      it 'returns false' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(false)
      end
    end

    context 'when down to robot move' do
      let(:move) do
        {
          robot: Board::RED,
          to: {
            row: 3,
            column: 1
          }
        }
      end

      it 'returns false' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(false)
      end
    end

    context 'when valid left move' do
      let(:move) do
        {
          robot: Board::RED,
          to: {
            row: 1,
            column: 0
          }
        }
      end

      it 'returns true' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when valid right move' do
      let(:move) do
        {
          robot: Board::RED,
          to: {
            row: 1,
            column: 3
          }
        }
      end

      it 'returns true' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when invalid right move through wall' do
      let(:move) do
        {
          robot: Board::BLUE,
          to: {
            row: 3,
            column: 3
          }
        }
      end

      it 'returns false' do
        result = board.valid_move?(move, robot_positions)
        expect(result).to eq(false)
      end
    end
  end

  describe '#solution?' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [5, 1, 1, 3],
          [8, 0, 0, 2],
          [8, 0, 0, 2],
          [12, 4, 4, 6]
        ].to_json, goals: [
          { number: 2, color: Board::RED },
          { number: 6, color: Board::BLUE }
        ].to_json, robot_colors: [Board::RED, Board::BLUE].to_json
      )
    end

    let(:robot_positions) do
      [
        { robot: Board::RED, position: { row: 3, column: 0 } },
        { robot: Board::BLUE, position: { row: 3, column: 3 } }
      ]
    end

    context 'when valid moves' do
      let(:moves) do
        [
          { robot: Board::RED, to: { row: 3, column: 2 } },
          { robot: Board::RED, to: { row: 0, column: 2 } }
        ]
      end

      it 'returns true' do
        goal = board.parsed_goals[0]
        result = board.solution?(robot_positions, goal, moves)
        expect(result).to eq(true)
      end
    end
  end
end
