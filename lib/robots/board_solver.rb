module Robots
  # Solver that tries to find a solution in the least amount of
  # steps for a certain robot configuration.
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
      # One solution is enough.
      return if candidate

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
      move_vertical(robot, robot_positions, :up)
    end

    # Move the given robot down.
    def down(robot, robot_positions)
      move_vertical(robot, robot_positions, :down)
    end

    # Move the given robot left.
    def left(robot, robot_positions)
      move_horizontally(robot, robot_positions, :left)
    end

    # Move the given robot right.
    def right(robot, robot_positions)
      move_horizontally(robot, robot_positions, :right)
    end

    private

    # Move vertically.
    def move_vertical(robot, robot_positions, direction)
      positions = robot_positions.deep_dup
      r_pos = position(robot, positions)
      increment = direction == :up ? -1 : 1
      cells = board.column_cells[r_pos[:column]]

      # Can't go trough the board.
      return false if r_pos[:row] == 0 && direction == :up
      return false if r_pos[:row] == cells.length - 1 && direction == :down

      idx = r_pos[:row]
      while idx >= 0
        cur_wall = direction == :up ? 1 : 4
        break if (cells[idx] & cur_wall).positive?

        next_idx = idx + increment
        next_wall = direction == :up ? 4 : 1
        if next_idx >= 0 && ((cells[next_idx] & next_wall).positive? ||
          board.contains_robot?(next_idx, r_pos[:column], positions))
          break
        end
        idx += increment
      end
      return false if idx == r_pos[:row]
      r_pos[:row] = idx
      positions
    end

    # Move horizontally.
    def move_horizontally(robot, robot_positions, direction)
      positions = robot_positions.deep_dup
      r_pos = position(robot, positions)
      increment = direction == :left ? -1 : 1
      cells = board.cells[r_pos[:row]]

      # Can't go trough the board.
      return false if r_pos[:column] == 0 && direction == :left
      return false if r_pos[:column] == cells.length - 1 && direction == :right

      idx = r_pos[:column]
      while idx >= 0
        # Current cell can't have left wall
        cur_wall = direction == :left ? 8 : 2
        break if (cells[idx] & cur_wall).positive?

        next_idx = idx + increment
        next_wall = direction == :left ? 2 : 8
        if next_idx >= 0 && ((cells[next_idx] & next_wall).positive? ||
          board.contains_robot?(r_pos[:row], next_idx, positions))
          break
        end
        idx += increment
      end
      return false if idx == r_pos[:column]
      r_pos[:column] = idx
      positions
    end

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
