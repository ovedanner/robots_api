# A game deals with a board and its state. Most of its values
# live in Redis.
class Game < ApplicationRecord
  belongs_to :room

  # The number of seconds after which the current best solution
  # can be provided.
  THINK_TIMEOUT = 5

  # The number of seconds the provider of the best solution has
  # to provide the moves.
  MOVE_TIMEOUT = 5

  include Redis::Objects

  list :cells, marshal: true
  list :goals, marshal: true
  list :robot_colors, marshal: true
  list :robot_positions, marshal: true
  list :completed_goals
  list :current_solution, marshal: true
  value :current_goal, marshal: true
  value :open_for_solution
  value :current_nr_moves
  value :current_winner
  value :current_winner_id
  value :timer_started
  lock :solve

  # Starts the game for the given board by randomly initializing the robots
  # and setting a current goal.
  def start_game(board = Robots::BoardGenerator.generate)
    # Clear any existing values.
    reset

    board.cells.each do |row|
      cells << row
    end

    board.goals.each do |goal|
      goals << goal
    end

    board.robot_colors.each do |color|
      robot_colors << color
    end

    initialize_robots
    initialize_goal
  end

  # Formats current board and game data to be sent to
  # users.
  def board_and_game_data
    {
      cells: cells.value,
      goals: goals.value,
      robot_colors: robot_colors.value,
      robot_positions: robot_positions.value,
      current_goal: current_goal.value
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

  # Indicates if there is a running timer.
  def has_timer_started?
    result = false

    solve_lock.lock do
      result = (timer_started.to_i > 0)
    end

    result
  end

  # Marks the end of solutions for the current goal.
  def close_for_solution
    solve_lock.lock do
      self.open_for_solution = 0
      logger.info("Closing game_#{room_id} for solutions!")
      GameChannel.broadcast_to(room_id,
                               action: 'closed_for_solutions',
                               current_winner: current_winner.value)
    end
  end

  # Marks the current goal as finished. If the user with the least number of
  # moves provided the right solution in time, he wins!
  def close_moves
    solve_lock.lock do
      # There needs to be a solution of the same length.
      if !current_solution&.empty? &&
        current_solution.length == current_nr_moves.to_i
        moves = current_solution.value
        positions = robot_positions.value
        goal = current_goal
        board = Robots::Board.new(cells, goals, robot_colors)
        if Robots::Board.is_solution?(board, positions, goal, moves)
          finish_goal
        end
      else
        logger.info("User #{current_winner.value} did not provide a solution in time!")
      end
    end
  end

  private

  # Randomly initialize robots.
  def initialize_robots
    possible_positions = []
    cells.each_with_index do |row, r_idx|
      row.each_with_index do |_, c_idx|
        possible_positions << [r_idx, c_idx] if cells[r_idx][c_idx] < 15
      end
    end

    colors = robot_colors.slice(0, robot_colors.length)
    nr_robots = colors.length
    nr_robots.times do
      pos = possible_positions.delete_at(rand(0...possible_positions.length))
      robot_positions <<
        {
          color: colors.delete_at(rand(0...colors.length)),
          position: {
            row: pos[0],
            column: pos[1]
          }
        }
    end
  end

  # Randomly sets the current goal.
  def initialize_goal
    self.current_goal = goals[rand(0...goals.length)]
  end

  # Reset properties.
  def reset
    %i[cells goals robot_colors robot_positions completed_goals].each do |prop|
      send(prop).send(:clear)
    end

    self.current_goal = nil
    self.open_for_solution = 1
    self.current_nr_moves = nil
    self.current_winner = nil
    self.current_winner_id = nil
    self.current_nr_moves = -1
    self.timer_started = 0
  end
end
