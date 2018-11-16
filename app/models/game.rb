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

  # Starts the game for the given board by randomly initializing the robots
  # and setting a current goal.
  def start_game!(board = Robots::BoardGenerator.generate)
    update!(board: board,
            robot_positions: board.get_random_robot_positions,
            current_goal: board.get_random_goal)
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
  def current_best_solution?(user, nr_moves)
    result = false

    solve_lock.lock do
      current = current_nr_moves.value.to_i
      if current == -1 || current > nr_moves
        self.current_nr_moves = nr_moves
        self.current_winner_id = user.id
        self.current_winner = user.firstname
        result = true
      end
    end

    result
  end

  # Is the current goal open for a solution? In other words, has
  # the think timer expired yet?
  def is_open_for_solution?
    result = false

    solve_lock.lock do
      result = (open_for_solution.to_i > 0)
    end

    result
  end

  def is_open_for_moves?
    result = false

    solve_lock.lock do
      result = (open_for_moves.to_i > 0)
    end
    logger.info("Open for moves: #{result}")

    result
  end

  # Indicates if there is a running timer.
  def has_timer_started?
    result = false

    solve_lock.lock do
      result = (timer_started.to_i > 0)
    end

    result
  end

  # Is the given user the current winner?
  def is_current_winner?(user)
    result = false

    solve_lock.lock do
      logger.info("User: #{user.id}, current winner: #{current_winner_id.value.to_i}")
      if user.id == current_winner_id.value.to_i
        result = true
      end
    end

    result
  end

  # Marks the end of solutions for the current goal.
  def close_for_solution
    solve_lock.lock do
      self.open_for_solution = 0
      self.open_for_moves = 1
      logger.info("Closing game_#{room_id} for solutions!")
      GameChannel.broadcast_to(room_id,
                               action: 'closed_for_solutions',
                               current_winner_id: current_winner_id.value,
                               current_winner: current_winner.value)
    end
  end

  # Marks the current goal as finished. If the user with the least number of
  # moves provided the right solution in time, he wins!
  def close_moves
    solve_lock.lock do
      # No more moves can be provided.
      self.open_for_moves = 0
      GameChannel.broadcast_to(room_id,
                               action: 'closed_for_moves')
    end
  end

  # Are the given moves a solution towards the current goal?
  def is_solution?(moves)
    positions = robot_positions.value
    goal = current_goal
    board = Robots::Board.new(cells, goals, robot_colors)
    board.is_solution?(positions, goal, moves)
  end
end
