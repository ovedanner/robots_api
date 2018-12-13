# A game deals with a board and its state. Most of its values
# live in Redis.
class Game < ApplicationRecord
  belongs_to :room
  belongs_to :current_winner, class_name: 'User', optional: true
  belongs_to :board

  validates :room, presence: true
  validates :board, presence: true
  validates_associated :current_winner
  validates :robot_positions, json: true, allow_blank: true
  validates :completed_goals, json: true, allow_blank: true
  validates :current_goal, json: true, allow_blank: true

  # The number of seconds after which the current best solution
  # can be provided.
  THINK_TIMEOUT = 10

  # The number of seconds the provider of the best solution has
  # to provide the moves.
  MOVE_TIMEOUT = 60

  # Used for locking the game while a solution is being checked
  # or moves are being provided
  include Redis::Objects
  lock :solve

  # Starts the game by randomly initializing the robots
  # and setting a current goal.
  def start_game!
    update!(
      completed_goals: [],
      current_nr_moves: -1,
      robot_positions: board.random_robot_positions,
      current_goal: board.random_goal)
  end

  # Formats current board and game data to be sent to
  # users.
  def board_and_game_data
    {
      cells: board.cells,
      goals: board.goals,
      robot_colors: board.robot_colors,
      robot_positions: robot_positions,
      current_goal: current_goal
    }
  end

  # Indicates that the given user claims to
  # have a solution in the given number of moves.
  # Returns whether or not that is the best one so
  # far.
  def current_best_solution?(nr_moves)
    current_nr_moves == -1 || current_nr_moves > nr_moves
  end

  # Is the given user the current winner?
  def current_winner?(user)
    user.id == current_winner.id
  end

  # Marks the end of solutions for the current goal.
  def close_for_solution!
    update!(open_for_solution: false, open_for_moves: true)
    GameChannel.broadcast_to(
      room_id,
      action: 'closed_for_solutions',
      current_winner_id: current_winner.id,
      current_winner: current_winner.firstname)
  end

  # Marks the current goal as finished. If the user with the least number of
  # moves provided the right solution in time, he wins!
  def close_for_moves!
    # No more moves can be provided.
    update!(open_for_moves: false)
    GameChannel.broadcast_to(
      room.id,
      action: 'closed_for_moves')
  end

  # Are the given moves a solution towards the current goal? If so
  # save new robot positions.
  def verify_solution!(moves)
    new_positions = board.solution?(robot_positions, current_goal, moves)
    if new_positions
      update!(robot_positions: new_positions)
      true
    else
      false
    end
  end

  # Called when the given user won the current goal.
  def next_goal!
    evaluate do
      completed = completed_goals
      completed << current_goal

      data = {
        completed_goals: completed,
        open_for_solution: false,
        open_for_moves: false,
        timer: nil,
        current_winner: nil,
        current_nr_moves: -1
      }
      new_goal = board.random_goal_not_in(completed)
      if new_goal
        # Get the game ready for the next round.
        data[:current_goal] = new_goal
        data[:open_for_solution] = true

        # Broadcast the new goal.
        update!(data)
        ActionCable.server.broadcast "game:#{room.id}", action: 'new_goal', goal: new_goal
      else
        # The game is finished!
        data[:current_goal] = nil
        update!(data)
        ActionCable.server.broadcast "game:#{room.id}", action: 'game_finished'
      end
    end
  end

  # Called to indicate that the given user claims to have a solution in the given
  # number of steps.
  def solution_in!(user, nr_moves)
    evaluate do
      if open_for_solution? &&
         current_best_solution?(nr_moves)

        data = {
          action: 'solution_in',
          current_winner: user.firstname,
          current_winner_id: user.id,
          current_nr_moves: nr_moves
        }

        # Start the game timer if it hasn't been done already.
        timer = nil
        attributes = {
          current_nr_moves: nr_moves,
          current_winner: user,
          open_for_moves: true
        }
        unless timer
          # Start the solution timer.
          start_solution_timer!
        end

        update!(attributes)

        # Inform subscribers that someone claims to have a solution.
        ActionCable.server.broadcast "game:#{room.id}", data
      end
    end
  end

  # The given user provided the given moves as a solution to work towards
  # the current goal.
  def solution_moves(user, moves)
    # Make sure the user providing the moves is the current
    # winner.
    moves = moves.map { |m| HashWithIndifferentAccess.new(m) }

    evaluate do
      if current_winner?(user) && open_for_moves?
        if verify_solution!(moves)
          # Clear the timer belonging to the game, so it will
          # not close for moves.
          update!(timer: nil)

          # Broadcast the winner.
          data = {
            action: 'goal_won_by',
            winner: user.firstname,
            moves: moves,
            robot_positions: robot_positions,
          }
          ActionCable.server.broadcast "game:#{room.id}", data

          return true
        end
      end

      return false
    end
  end

  # Start the solution timer.
  def start_solution_timer!
    timer_id = SecureRandom.hex(10)
    update!(timer: timer_id)

    Rails.application.executor.wrap do
      Concurrent::ScheduledTask.execute(Game::THINK_TIMEOUT) do
        evaluate do
          close_for_solution!
          Concurrent::ScheduledTask.execute(Game::MOVE_TIMEOUT) do
            # Only close for moves if the timer is still the right one
            # for the game
            reload
            evaluate(&method(:close_for_moves!)) if timer == timer_id
          end
        end
      end
    end
  end

  # Evaluates the given block using a Redis lock on the game.
  def evaluate
    solve_lock.lock do
      yield
    end
  end
end
