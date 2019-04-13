class GameService
  def initialize(game)
    @game = game
  end

  # Starts the game by randomly initializing the robots
  # and setting a current goal.
  def start
    @game.update!(
      completed_goals: [],
      current_nr_moves: -1,
      robot_positions: @game.board.random_robot_positions,
      current_goal: @game.board.random_goal)
  end

  # Called to indicate that the given user claims to have a solution in the given
  # number of steps.
  def solution_in(user, nr_moves)
    @game.evaluate do
      if @game.open_for_solution? &&
         @game.current_best_solution?(nr_moves)

        data = {
          action: 'solution_in',
          seconds_left: Game::THINK_TIMEOUT,
          current_winner: user.firstname,
          current_winner_id: user.id,
          current_nr_moves: nr_moves
        }

        # Start the game timer if it hasn't been done already.
        @game.timer = nil
        attributes = {
          current_nr_moves: nr_moves,
          current_winner: user,
          open_for_moves: true
        }
        unless @game.timer
          # Start the solution timer.
          start_solution_timer
        end

        @game.update!(attributes)

        # Inform subscribers that someone claims to have a solution.
        ActionCable.server.broadcast "game:#{@game.room.id}", data
      end
    end
  end

  # Set everything up for the next goal.
  def next_goal
    @game.evaluate do
      completed = @game.completed_goals
      completed << @game.current_goal

      data = {
        completed_goals: completed,
        open_for_solution: false,
        open_for_moves: false,
        timer: nil,
        current_winner: nil,
        current_nr_moves: -1
      }
      new_goal = @game.board.random_goal_not_in(completed)
      if new_goal
        # Get the game ready for the next round.
        data[:current_goal] = new_goal
        data[:open_for_solution] = true

        # Broadcast the new goal.
        @game.update!(data)
        ActionCable.server.broadcast "game:#{@game.room.id}",
                                     action: 'new_goal',
                                     goal: new_goal,
                                     robot_positions: @game.robot_positions
      else
        # The game is finished!
        data[:current_goal] = nil
        @game.update!(data)

        # Everybody has to mark themselves as ready again.
        @game.room.no_users_ready!

        ActionCable.server.broadcast "game:#{@game.room.id}", action: 'game_finished'
      end
    end
  end

  # Start the solution timer.
  def start_solution_timer
    timer_id = SecureRandom.hex(10)
    @game.update!(timer: timer_id)

    Rails.application.executor.wrap do
      Concurrent::ScheduledTask.execute(Game::THINK_TIMEOUT) do
        @game.evaluate do
          close_for_solution
          Concurrent::ScheduledTask.execute(Game::MOVE_TIMEOUT) do
            # Only close for moves if the timer is still the right one
            # for the game
            @game.reload
            close_for_moves if @game.timer == timer_id
          end
        end
      end
    end
  end

  # The given user provided the given moves as a solution to work towards
  # the current goal.
  def solution_moves(user, moves)
    # Make sure the user providing the moves is the current
    # winner.
    @game.evaluate do
      if @game.current_winner?(user) && @game.open_for_moves?
        if verify_solution(moves)
          # Clear the timer belonging to the game, so it will
          # not close for moves.
          @game.update!(timer: nil)

          # Everyone has to mark themselves as ready again.
          @game.room.no_users_ready!

          # Broadcast the winner.
          data = {
            action: 'goal_won_by',
            winner: user.firstname,
            moves: moves,
          }
          ActionCable.server.broadcast "game:#{@game.room.id}", data

          true
        end
      else
        false
      end
    end
  end

  # Are the given moves a solution towards the current goal? If so
  # save new robot positions.
  def verify_solution(moves)
    new_positions = @game.board.solution?(@game.robot_positions, @game.current_goal, moves)
    if new_positions
      @game.update!(robot_positions: new_positions)
      true
    else
      false
    end
  end

  # Marks the end of solutions for the current goal.
  def close_for_solution
    @game.update!(open_for_solution: false, open_for_moves: true)
    GameChannel.broadcast_to(
      @game.room_id,
      action: 'closed_for_solutions',
      seconds_left: Game::MOVE_TIMEOUT,
      current_winner_id: @game.current_winner.id,
      current_winner: @game.current_winner.firstname)
  end

  # Marks the current goal as finished. If the user with the least number of
  # moves provided the right solution in time, he wins!
  def close_for_moves
    # No more moves can be provided.
    @game.update!(open_for_moves: false)

    # Everybody has to mark themselves as ready again.
    @game.room.no_users_ready!

    # Let everyone know.
    GameChannel.broadcast_to(
      @game.room.id,
      action: 'closed_for_moves')
  end

  # Tries to generate a solution and return candidate moves.
  def generate_solution
    solver = Robots::BoardSolver.new(@game.board)
    solver.solve(@game.robot_positions, @game.current_goal)
    solver.candidate
  end

  # Starts a new game in the room.
  def self.start_new_game(room)
    # Clear any existing game in the room.
    game = Game.find_by_room_id(room.id)
    game&.destroy

    # Generate a new board.
    board = Robots::BoardGenerator.generate
    board.save!

    # Create a new game and broadcast game and
    # board data to the users.
    game = Game.new(
      room: room,
      open_for_solution: true,
      open_for_moves: false,
      board: board)
    if game.save
      GameService.new(game).start
      data = { action: 'start_new_game' }.merge(game.board_and_game_data)
      ActionCable.server.broadcast "game:#{room.id}", data
    else
      logger.error("Could not create new game for room #{room.id}")
    end
  end
end
