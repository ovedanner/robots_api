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

  def parsed_robot_positions
    result = []
    JSON.parse(robot_positions).each { |p| result << HashWithIndifferentAccess.new(p) }
    result
  end

  def parsed_completed_goals
    result = []
    JSON.parse(completed_goals).each { |g| result << HashWithIndifferentAccess.new(g) }
    result
  end

  def parsed_current_goal
    HashWithIndifferentAccess.new(JSON.parse(current_goal))
  end

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
      completed_goals: [].to_json,
      current_nr_moves: -1,
      robot_positions: board.get_random_robot_positions.to_json,
      current_goal: board.random_goal.to_json)
  end

  # Formats current board and game data to be sent to
  # users.
  def board_and_game_data
    {
      cells: board.parsed_cells,
      goals: board.parsed_goals,
      robot_colors: board.parsed_robot_colors,
      robot_positions: parsed_robot_positions,
      current_goal: parsed_current_goal
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
    GameChannel.broadcast_to(room_id,
                             action: 'closed_for_solutions',
                             current_winner_id: current_winner.id,
                             current_winner: current_winner.firstname)
  end

  # Marks the current goal as finished. If the user with the least number of
  # moves provided the right solution in time, he wins!
  def close_for_moves!
    # No more moves can be provided.
    update!(open_for_moves: false)
    GameChannel.broadcast_to(room.id,
                             action: 'closed_for_moves')
  end

  # Are the given moves a solution towards the current goal?
  def solution?(moves)
    board.solution?(parsed_robot_positions, parsed_current_goal, moves)
  end

  # Called when the given user won the current goal.
  def next_goal!()
    completed = parsed_completed_goals
    completed << parsed_current_goal

    new_goal = board.random_goal_not_in(completed)
    if new_goal
      # Get the game ready for the next round.
      update!(
        current_goal: new_goal.to_json,
        completed_goals: completed.to_json,
        open_for_solution: true,
        open_for_moves: false,
        timer_started: false,
        current_winner: nil,
        current_nr_moves: -1
      )

      new_goal
    else
      false
    end
  end

  # Start the solution timer.
  def start_solution_timer(moves_timer)
    Rails.application.executor.wrap do
      Concurrent::ScheduledTask.execute(Game::THINK_TIMEOUT) do
        evaluate do
          close_for_solution!
          moves_timer.execute
        end
      end
    end
  end

  # Get the moves timer.
  def moves_timer
    Concurrent::ScheduledTask.new(Game::MOVE_TIMEOUT) do
      evaluate(&method(:close_for_moves!))
    end
  end

  # Evaluates the given block using a mutex on the game.
  def evaluate
    solve_lock.lock do
      yield
    end
  end
end
