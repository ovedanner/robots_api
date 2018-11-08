module Robots
  # A board, optionally with positions of its robots and a current goal. Note
  # that a board is square (NxN).
  class Board

    attr_accessor :cells, :goals, :robot_colors

    def initialize(cells, goals, robot_colors)
      @cells = cells
      @goals = goals
      @robot_colors = robot_colors
    end

    # Returns the cells in columns instead of rows.
    def column_cells
      columns = []

      cells.length.times do |i|
        column = []
        cells.length.times do |j|
          column << cells[j][i]
        end
        columns << column
      end

      columns
    end

    # Checks if the given goal is reached by performing the given
    # moves on the given board with the given robot positions.
    def self.is_solution?(board, robot_positions, goal, moves)
      # Clone robot positions because we want to make modifications.
      r_positions = robot_positions.deep_dup

      result = moves.all? do |move|
        valid_move?(board, move, r_positions)
      end

      if result
        # Check if the goal is reached.
      end
    end

    def self.valid_move?(board, move, robot_positions)
      valid = true
      cells = board.cells
      column_cells = board.column_cells

      robot = move[:robot]
      to = move[:to]
      pos = robot_positions.shift { |p| p.color == robot }
      return false unless pos

      from_row = pos[:position][:row]
      from_column = pos[:position][:column]
      to_row = to[:row]
      to_column = to[:column]

      # You can't move diagonally.
      return false if from_row != to_row && from_column != to_column

      if from_row == to_row
        # Moving horizontally.
        if from_column < to_column
          # Moving right
          cells[from_row].each_with_index do |cell, idx|
            if idx == from_column
              valid &&= (cell & 2).zero?
            elsif idx > from_column && idx < to_column
              valid &&=
                valid_path_cell?(cells, from_row, idx, :right, robot_positions)
            elsif idx == to_column
              valid &&=
                valid_target_cell?(cells, from_row, idx, :right, robot_positions)
            end
          end
        else
          # Moving left.
          cells[from_row].each_with_index do |cell, idx|
            if idx == from_column
              valid &&= (cell & 8).zero?
            elsif idx > from_column && idx < to_column
              valid &&=
                valid_path_cell?(cells, from_row, idx, :left, robot_positions)
            elsif idx == to_column
              valid &&=
                valid_target_cell?(cells, from_row, idx, :left, robot_positions)
            end
          end
        end
      else
        # Moving vertically.
        if from_row < to_row
          # Moving down.
          column_cells[from_column].each_with_index do |cell, idx|
            if idx == from_row
              valid &&= (cell & 4).zero?
            elsif idx > from_row && idx < to_row
              valid &&=
                valid_path_cell?(cells, idx, from_column, :down, robot_positions)
            elsif idx == to_row
              valid &&=
                valid_target_cell?(cells, idx, from_column, :down, robot_positions)
            end
          end
        else
          # Moving up.
          column_cells[from_column].each_with_index do |cell, idx|
            if idx == from_row
              valid &&= (cell & 1).zero?
            elsif idx < from_row && idx > to_row
              valid &&=
                valid_path_cell?(cells, idx, from_column, :up, robot_positions)
            elsif idx == to_row
              valid &&=
                valid_target_cell?(cells, idx, from_column, :up, robot_positions)
            end
          end
        end
      end

      valid
    end

    # Is the given cell a reachable path cell between the start and target cell?
    def self.valid_path_cell?(cells, row, column, direction, robot_positions)
      result = !self.contains_robot?(row, column, robot_positions)

      case direction
      when :up, :down
        result &&= (cells[row][column] & 5).zero?
      when :left, :right
        result &&= (cells[row][column] & 10).zero?
      else
        result = false
      end

      result
    end

    # Is there are robot at the given coordinates?
    def self.contains_robot?(row, column, robot_positions)
      robot_positions.any? do |p|
        p[:position][:row] == row && p[:position][:column] == column
      end
    end

    # Does the next cell in the given direction exist?
    def self.next_cell_exists?(cells, row, column, direction)
      case direction
      when :up
        (row - 1) >= 0
      when :down
        (row + 1) < (cells.length)
      when :left
        (column - 1) >= 0
      when :right
        (column + 1) < cells[row].length
      else
        false
      end
    end

    # Is the given cell a valid target cell coming from the given direction.
    def self.valid_target_cell?(cells, row, column, direction, robot_positions)
      result = !contains_robot?(row, column, robot_positions)

      case direction
      when :up
        result &&= (cells[row][column] & 1).positive? ||
                   (next_cell_exists?(cells, row, column, direction) &&
                     contains_robot?(row - 1, column, robot_positions))
      when :down
        result &&= (cells[row][column] & 4).positive? ||
                   (next_cell_exists?(cells, row, column, direction) &&
                     contains_robot?(row + 1, column, robot_positions))
      when :left
        result &&= (cells[row][column] & 8).positive? ||
                   (next_cell_exists?(cells, row, column, direction) &&
                     contains_robot?(row, column - 1, robot_positions))
      when :right
        result &&= (cells[row][column] & 2).positive? ||
                   (next_cell_exists?(cells, row, column, direction) &&
                     contains_robot?(row, column + 1, robot_positions))
      else
        result = false
      end

      result
    end
  end
end
