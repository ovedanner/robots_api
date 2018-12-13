require 'rails_helper'

RSpec.describe Game, type: :model do
  # Default user, room and board for game tests.
  let(:user) { FactoryBot.create('user') }
  let(:room) do
    FactoryBot.create(:room_with_member, member: user, owner: user)
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

  describe '#start_game' do
    let(:game) { FactoryBot.create('game', room: room, board: board) }

    context 'when passing in a board' do
      it 'initializes robots and the current goal' do
        game.start_game!
        positions = game.robot_positions
        goal = indifferent_hash(game.current_goal)
        moves = game.current_nr_moves

        expect(positions.length).to eq(2)
        expect(goal[:number]).to be_in([2, 6])
        expect(goal[:color]).to be_in(%w(red blue))
        expect(moves).to be(-1)
      end
    end
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

  describe '#close_for_moves!' do
    let(:game) do
      FactoryBot.create(
        'game',
        room: room,
        board: board,
        open_for_moves: true)
    end

    context 'when game is open for moves' do
      it 'closes the game' do
        game.close_for_moves!
        expect(game.open_for_moves).to be(false)
      end
    end
  end

  describe '#close_for_solution!' do
    let(:game) do
      FactoryBot.create(
        'game',
        room: room,
        board: board,
        current_winner: user,
        open_for_moves: false,
        open_for_solution: true)
    end

    context 'when game is open for solutions' do
      it 'closes solutions and opens for moves' do
        game.close_for_solution!
        expect(game.open_for_solution).to be(false)
        expect(game.open_for_moves).to be(true)
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

  describe '#next_goal!' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [9, 1, 3],
          [8, 0, 2],
          [12, 4, 6]
        ], goals: [
          { number: 1, color: Board::RED },
          { number: 8, color: Board::BLUE }
        ], robot_colors: [Board::RED, Board::BLUE]
      )
    end

    context 'when next goal available' do
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

      it 'sets the proper goal' do
        data = {
          action: 'new_goal',
          goal: { color: Board::BLUE, number: 8 }
        }
        expect(action_cable).to receive(:broadcast).with("game:#{room.id}", data)

        game.next_goal!

        updated_game = Game.find(game.id)
        new_goal = indifferent_hash(updated_game.current_goal)

        expect(new_goal[:number]).to eq(8)
        expect(new_goal[:color]).to eq(Board::BLUE)

        expect(updated_game.open_for_solution).to eq(true)
        expect(updated_game.open_for_moves).to eq(false)
        expect(updated_game.current_nr_moves).to eq(-1)
        expect(updated_game.current_winner).to eq(nil)
      end
    end

    context 'when no more goals available' do
      let(:game) do
        FactoryBot.create(
          'game',
          room: room,
          board: board,
          completed_goals: [
            { number: 8, color: Board::BLUE }
          ],
          robot_positions: [
            { robot: Board::RED, position: { row: 2, column: 2 } },
            { robot: Board::BLUE, position: { row: 2, column: 0 } }
          ],
          current_goal: { number: 1, color: Board::RED })
      end

      it 'finishes the game' do
        expect(action_cable).to receive(:broadcast).with("game:#{room.id}", action: 'game_finished')

        game.next_goal!

        updated_game = Game.find(game.id)
        expect(updated_game.current_goal).to eq(nil)
        expect(updated_game.open_for_solution).to eq(false)
        expect(updated_game.open_for_moves).to eq(false)
        expect(updated_game.current_nr_moves).to eq(-1)
        expect(updated_game.current_winner).to eq(nil)
      end
    end
  end

  describe '#verify_solution!' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [9, 1, 3],
          [8, 0, 2],
          [12, 4, 6]
        ], goals: [
          { number: 1, color: Board::RED },
          { number: 8, color: Board::BLUE }
        ], robot_colors: [Board::RED, Board::BLUE]
      )
    end

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

    context 'with valid moves' do
      let(:valid_moves) do
        [
          { robot: Board::RED, to: { row: 2, column: 1 } },
          { robot: Board::RED, to: { row: 0, column: 1 } }
        ]
      end

      it 'updates robot positions' do
        new_positions = [
          { robot: Board::RED, position: { row: 0, column: 1 } },
          { robot: Board::BLUE, position: { row: 2, column: 0 } }
        ]
        game.verify_solution!(valid_moves)
        actual = indifferent_array(Game.find(game.id).robot_positions)
        expect(actual).to match_array(new_positions)
      end
    end

    context 'with invalid moves' do
      let(:valid_moves) do
        [
          { robot: Board::RED, to: { row: 2, column: 1 } },
          { robot: Board::RED, to: { row: 1, column: 1 } }
        ]
      end

      it 'fails' do
        expect(game.verify_solution!(valid_moves)).to be(false)
      end
    end
  end

  describe '#solution_in!' do
    let(:new_winner) do
      winner = FactoryBot.create('user')
      FactoryBot.create('room_user', room: room, user: winner)
      winner
    end

    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [9, 1, 3],
          [8, 0, 2],
          [12, 4, 6]
        ], goals: [
          { number: 1, color: Board::RED },
          { number: 8, color: Board::BLUE }
        ], robot_colors: [Board::RED, Board::BLUE]
      )
    end

    let(:game) do
      FactoryBot.create(
        'game',
        room: room,
        current_nr_moves: 10,
        open_for_solution: true,
        open_for_moves: false,
        current_winner: user,
        board: board,
        robot_positions: [
          { robot: Board::RED, position: { row: 2, column: 2 } },
          { robot: Board::BLUE, position: { row: 2, column: 0 } }
        ],
        current_goal: { number: 1, color: Board::RED })
    end

    context 'when a new best number of moves is provided' do
      it 'updates the game and broadcasts' do
        broadcast_data = {
          action: 'solution_in',
          current_winner: new_winner.firstname,
          current_winner_id: new_winner.id,
          current_nr_moves: 8
        }
        expect(action_cable).to receive(:broadcast).with("game:#{room.id}", broadcast_data)

        timer = game.solution_in!(new_winner, 8)
        expect(timer).to be_instance_of(Concurrent::ScheduledTask)

        updated_game = Game.find(game.id)
        expect(updated_game.current_nr_moves).to eq(8)
        expect(updated_game.current_winner).to eq(new_winner)
        expect(updated_game.open_for_moves).to eq(true)
      end
    end

    context 'when the provided number of moves is not optimal' do
      it 'does nothing' do
        expect(action_cable).to_not receive(:broadcast)

        timer = game.solution_in!(new_winner, 13)
        expect(timer).to be_falsey

        updated_game = Game.find(game.id)
        expect(updated_game.current_nr_moves).to eq(10)
        expect(updated_game.current_winner).to eq(user)
        expect(updated_game.open_for_moves).to eq(false)
      end
    end
  end
end
