require 'rails_helper'

RSpec.describe GameService do
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

  subject { GameService.new(game) }

  describe '#start' do
    let(:game) { FactoryBot.create('game', room: room, board: board) }

    context 'when passing in a board' do
      it 'initializes robots and the current goal' do
        subject.start

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

  describe '#close_for_solution' do
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
        subject.close_for_solution

        expect(game.open_for_solution).to be(false)
        expect(game.open_for_moves).to be(true)
      end
    end
  end

  describe '#close_for_moves' do
    let(:game) do
      FactoryBot.create(
        'game',
        room: room,
        board: board,
        open_for_moves: true)
    end

    context 'when game is open for moves' do
      it 'closes the game' do
        subject.close_for_moves
        expect(game.open_for_moves).to be(false)

        room_users = game.room.room_users
        expect(room_users.size).to eq(1)
        expect(room_users.first.ready).to eq(false)
      end
    end
  end

  describe '#next_goal' do
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
          goal: { color: Board::BLUE, number: 8 },
          robot_positions: JSON.parse([
            { robot: Board::RED, position: { row: 2, column: 2 } },
            { robot: Board::BLUE, position: { row: 2, column: 0 } }
          ].to_json)
        }
        expect(action_cable).to receive(:broadcast).with("game:#{room.id}", data)

        subject.next_goal

        game.reload
        new_goal = indifferent_hash(game.current_goal)

        expect(new_goal[:number]).to eq(8)
        expect(new_goal[:color]).to eq(Board::BLUE)

        expect(game.open_for_solution).to eq(true)
        expect(game.open_for_moves).to eq(false)
        expect(game.current_nr_moves).to eq(-1)
        expect(game.current_winner).to eq(nil)
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

        subject.next_goal

        game.reload

        expect(game.current_goal).to eq(nil)
        expect(game.open_for_solution).to eq(false)
        expect(game.open_for_moves).to eq(false)
        expect(game.current_nr_moves).to eq(-1)
        expect(game.current_winner).to eq(nil)
      end
    end
  end

  describe '#verify_solution' do
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
        subject.verify_solution(valid_moves)

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
        expect(subject.verify_solution(valid_moves)).to be(false)
      end
    end
  end

  describe '#solution_in' do
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
          seconds_left: Game::THINK_TIMEOUT,
          current_nr_moves: 8
        }
        expect(action_cable).to receive(:broadcast).with("game:#{room.id}", broadcast_data)

        subject.solution_in(new_winner, 8)

        updated_game = Game.find(game.id)
        expect(updated_game.timer).to match(/[a-z0-9]{20}/)
        expect(updated_game.current_nr_moves).to eq(8)
        expect(updated_game.current_winner).to eq(new_winner)
        expect(updated_game.open_for_moves).to eq(true)
      end
    end

    context 'when the provided number of moves is not optimal' do
      it 'does nothing' do
        expect(action_cable).to_not receive(:broadcast)

        timer = subject.solution_in(new_winner, 13)
        expect(timer).to be_falsey

        updated_game = Game.find(game.id)
        expect(updated_game.current_nr_moves).to eq(10)
        expect(updated_game.current_winner).to eq(user)
        expect(updated_game.open_for_moves).to eq(false)
      end
    end
  end

  describe '.start_new_game' do
    let(:room) do
      FactoryBot.create(:room_with_member, member: user, open: true)
    end

    context 'when room owner starts a new game' do
      it 'will succeed' do
        GameService.start_new_game(room)

        game = Game.find_by_room_id(room.id)

        expect(game.board).to be_instance_of(Board)
        expect(game.open_for_solution).to eq(true)
        expect(game.open_for_moves).to eq(false)
        expect(game.completed_goals).to match_array([])
        expect(game.current_nr_moves).to eq(-1)
        expect(game.robot_positions).to be_instance_of(Array)
        expect(game.current_goal).to be_instance_of(Hash)
      end
    end
  end
end
