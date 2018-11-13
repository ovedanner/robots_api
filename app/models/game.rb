# A game deals with a board and its state. Most of its values
# live in Redis.
class Game < ApplicationRecord
  belongs_to :room

  include Redis::Objects

  list :cells, marshal: true
  list :goals, marshal: true
  list :robot_colors, marshal: true
  list :robot_positions, marshal: true
  list :completed_goals
  list :current_solution, marshal: true
  value :current_goal, marshal: true
  value :start
  value :current_nr_moves
  value :current_winner
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

    self.current_nr_moves = -1
    self.start = true
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
        self.current_winner = user.firstname
        result = true
      end
    end

    result
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

  # Checks if the given moves provide a solution to the
  # current board state.
  # def is_solution?(moves)
  #
  # end

  # Reset properties.
  def reset
    %i[cells goals robot_colors robot_positions completed_goals].each do |prop|
      send(prop).send(:clear)
    end

    self.current_goal = nil
    self.start = false
  end
end
