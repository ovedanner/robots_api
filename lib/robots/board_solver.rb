module Robots
  class BoardSolver
    attr_reader :board, :robots
    attr_accessor :candidate

    def initialize(board)
      @board = board
      @robots = board.robot_colors
      @candidate = nil
    end

    def solve(robot_positions, goal)
      goal = HashWithIndifferentAccess.new(goal)
      positions = []
      robot_positions.each { |p| positions << HashWithIndifferentAccess.new(p) }

      # Try an incrementing number of moves.
      nr_moves = 1
      until candidate
        solve_in(positions, goal, nr_moves)
        nr_moves += 1
      end
    end

    # Tries to recursively work towards the given goal.
    def solve_in(robot_positions, goal, nr_moves, moves = [])
      # One solution is enough. We also return if there is
      # no way we could reach the goal from the current positions.
      return if candidate || goal_unreachable?(robot_positions, goal, nr_moves)

      # Done, did we reach the goal?
      if nr_moves == 0
        self.candidate = moves if goal_reached?(robot_positions, goal)
        return
      end

      # Can only move target robot if we have one move left.
      robots_to_move = nr_moves == 1 ? [goal[:color]] : robots

      robots_to_move.each do |r|
        [:up, :down, :left, :right].each do |direction|
          # Only continue if this does not 'negate' the last move.
          next if moves.length > 0 && opposite_move?(moves.last, r, direction)

          new_positions = send(direction, r, robot_positions)
          next unless new_positions

          new_moves = moves.clone
          new_moves << { robot: r, to: position(r, new_positions), direction: direction }
          solve_in(new_positions, goal, nr_moves - 1, new_moves)
        end
      end
    end

    # Move the given robot up.
    def up(robot, robot_positions)
      positions = robot_positions.deep_dup
      r_pos = position(robot, positions)

      # Can't go trough the board.
      return false if r_pos[:row] == 0

      cells = board.column_cells[r_pos[:column]]
      idx = r_pos[:row]
      while idx >= 0
        # Current cell can't have top wall
        break if (cells[idx] & 1).positive?

        # Next cell can't have bottom wall or robot
        if idx - 1 >= 0 && ((cells[idx - 1] & 4).positive? || board.contains_robot?(idx - 1, r_pos[:column], positions))
          break
        end
        idx -= 1
      end
      return false if idx == r_pos[:row]
      r_pos[:row] = idx
      positions
    end

    # Move the given robot down.
    def down(robot, robot_positions)
      positions = robot_positions.deep_dup
      r_pos = position(robot, positions)

      # Can't go trough the board.
      return false if r_pos[:row] == board.cells.length - 1

      cells = board.column_cells[r_pos[:column]]
      idx = r_pos[:row]
      while idx < cells.length
        # Current cell can't have bottom wall
        break if (cells[idx] & 4).positive?

        # Next cell can't have top wall or robot
        if idx + 1 >= 0 && ((cells[idx + 1] & 1).positive? || board.contains_robot?(idx + 1, r_pos[:column], positions))
          break
        end
        idx += 1
      end
      return false if idx == r_pos[:row]
      r_pos[:row] = idx
      positions
    end

    # Move the given robot left.
    def left(robot, robot_positions)
      positions = robot_positions.deep_dup
      r_pos = position(robot, positions)

      # Can't go trough the board.
      return false if r_pos[:column] == 0

      cells = board.cells[r_pos[:row]]
      idx = r_pos[:column]
      while idx >= 0
        # Current cell can't have left wall
        break if (cells[idx] & 8).positive?

        # Next cell can't have right wall or robot
        if idx - 1 >= 0 && ((cells[idx - 1] & 2).positive? || board.contains_robot?(r_pos[:row], idx - 1, positions))
          break
        end
        idx -= 1
      end
      return false if idx == r_pos[:column]
      r_pos[:column] = idx
      positions
    end

    # Move the given robot right.
    def right(robot, robot_positions)
      positions = robot_positions.deep_dup
      r_pos = position(robot, positions)

      # Can't go trough the board.
      return false if r_pos[:column] == board.cells.length - 1

      cells = board.cells[r_pos[:row]]
      idx = r_pos[:column]
      while idx < cells.length
        # Current cell can't have right wall
        break if (cells[idx] & 2).positive?

        # Next cell can't have left wall or robot
        if idx + 1 >= 0 && ((cells[idx + 1] & 8).positive? || board.contains_robot?(r_pos[:row], idx + 1, positions))
          break
        end
        idx += 1
      end
      return false if idx == r_pos[:column]
      r_pos[:column] = idx
      positions
    end

    private

    # Retrieves the position of the given robot.
    def position(robot, robot_positions)
      r_pos = robot_positions.find { |p| p[:robot] == robot }
      r_pos[:position]
    end

    # Is the given goal reached by having the robots in the given
    # position?
    def goal_reached?(robot_positions, goal)
      r_pos = position(goal[:color], robot_positions)
      r_number = (r_pos[:row] * board.cells.length) + r_pos[:column]

      r_number == goal[:number]
    end

    # Determines if the goal is even still reachable from the given
    # robot positions. The fastest you could possibly go is the
    # Euclidian distance between the current cell of the target robot
    # and the goal cell.
    def goal_unreachable?(robot_positions, goal, moves_left)
      r_pos = position(goal[:color], robot_positions)
      goal_row = goal[:number] / board.cells.length
      goal_column = goal[:number] % board.cells.length
      fastest = (goal_row - r_pos[:row]).abs + (goal_column - r_pos[:column])

      fastest > moves_left
    end

    # Determines if the given move is 'negated' by moving
    # the given robot in the given direction
    def opposite_move?(move, robot, direction)
      return false if move[:robot] != robot
      case move[:direction]
      when :up
        return direction == :down
      when :down
        return direction == :up
      when :left
        return direction == :right
      else
        return direction == :left
      end
    end
  end
end
