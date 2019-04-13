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
  MOVE_TIMEOUT = 20

  # Used for locking the game while a solution is being checked
  # or moves are being provided
  include Redis::Objects
  lock :solve

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

  # Evaluates the given block using a Redis lock on the game.
  def evaluate
    solve_lock.lock do
      yield
    end
  end
end
