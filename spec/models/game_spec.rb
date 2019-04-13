require 'rails_helper'

RSpec.describe Game, type: :model do
  # Default user, room and board for game tests.
  let(:user) { FactoryBot.create('user') }
  let(:room) do
    FactoryBot.create(
      :room_with_member,
      member: user,
      owner: user,
      ready: true)
  end
  let(:board) do
    FactoryBot.create(
      'board',
      cells: [
        [5, 1, 1, 3],
        [8, 0, 0, 2],
        [8, 0, 0, 2],
        [12, 4, 4, 14]
      ], goals: [
        { number: 2, color: Board::RED },
        { number: 6, color: Board::BLUE }
      ], robot_colors: [Board::RED, Board::BLUE])
  end

  # Used to verify broadcast messages.
  let(:action_cable) { ActionCable.server }

  describe '#room' do
    it { is_expected.to validate_presence_of(:room) }
    it { is_expected.to belong_to(:room) }
  end

  describe '#board' do
    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to belong_to(:board) }
  end

  describe '#current_winner' do
    it { is_expected.to belong_to(:current_winner).optional }
  end

  describe '#robot_positions' do
    let(:valid_robot_positions) do
        [{"color": "red", "position": {"row": 1, "column": 2}}]
    end

    it { is_expected.to allow_value(nil).for(:robot_positions) }
    it { is_expected.not_to allow_value('invalid JSON').for(:robot_positions) }
    it { is_expected.not_to allow_value(4).for(:robot_positions) }

    it { is_expected.to allow_value(valid_robot_positions).for(:robot_positions) }
  end

  describe '#completed_goals' do
    let(:valid_completed_goals) do
        [{"number": 2, "color": "red"}]
    end

    it { is_expected.to allow_value(nil).for(:completed_goals) }
    it { is_expected.not_to allow_value('invalid JSON').for(:completed_goals) }
    it { is_expected.not_to allow_value(4).for(:completed_goals) }

    it { is_expected.to allow_value(valid_completed_goals).for(:completed_goals) }
  end

  describe '#current_goal' do
    let(:valid_current_goal) do
        {"number": 2, "color": "red"}
    end

    it { is_expected.to allow_value(nil).for(:current_goal) }
    it { is_expected.not_to allow_value('invalid JSON').for(:current_goal) }
    it { is_expected.not_to allow_value(4).for(:current_goal) }

    it { is_expected.to allow_value(valid_current_goal).for(:current_goal) }
  end

  describe '#current_winner?' do
    let(:winner) { FactoryBot.create('user') }
    let(:game) do
      FactoryBot.create(
        'game',
        room: room,
        board: board,
        current_winner: winner)
    end

    context 'with a current winner' do
      it 'returns true' do
        expect(game.current_winner?(winner)).to be(true)
      end
    end

    context 'with a member that is not a winner' do
      it 'returns false' do
        expect(game.current_winner?(user)).to be(false)
      end
    end
  end

  describe '#current_best_solution?' do
    context 'when no moves exist' do
      let(:game) do
        FactoryBot.create(
          'game',
          room: room,
          board: board,
          current_nr_moves: -1)
      end

      it 'returns true' do
        expect(game.current_best_solution?(12)).to be(true)
      end
    end

    context 'when better moves exist' do
      let(:game) do
        FactoryBot.create(
          'game',
          room: room,
          board: board,
          current_nr_moves: 10)
      end

      it 'returns false' do
        expect(game.current_best_solution?(12)).to be(false)
      end
    end

    context 'when no better moves exist' do
      let(:game) do
        FactoryBot.create(
          'game',
          room: room,
          board: board,
          current_nr_moves: 15)
      end

      it 'returns true' do
        expect(game.current_best_solution?(12)).to be(true)
      end
    end
  end

  describe '#board_and_game_data' do
    let(:game) do
      FactoryBot.create(
        'game',
        room: room,
        board: board,
        robot_positions: [
          { robot: Board::RED, position: { row: 2, column: 2 } },
          { robot: Board::BLUE, position: { row: 2, column: 0 } }
        ],
        current_goal: { number: 1, color: Board::RED })
    end

    context 'when game has just started' do
      it 'returns game and board data' do
        data = game.board_and_game_data
        expect(data[:cells]).to match_array(
          [
            [5, 1, 1, 3],
            [8, 0, 0, 2],
            [8, 0, 0, 2],
            [12, 4, 4, 14]
          ])
        expect(indifferent_array(data[:goals])).to match_array([
          { number: 2, color: Board::RED },
          { number: 6, color: Board::BLUE }
        ])
        expect(indifferent_array(data[:robot_colors])).to match_array([Board::RED, Board::BLUE])
        expect(indifferent_array(data[:robot_positions])).to match_array(
          [
            { robot: Board::RED, position: { row: 2, column: 2 } },
            { robot: Board::BLUE, position: { row: 2, column: 0 } }
          ])
        expect(indifferent_hash(data[:current_goal])[:number]).to eq(1)
        expect(indifferent_hash(data[:current_goal])[:color]).to eq(Board::RED)
      end
    end
  end
end
