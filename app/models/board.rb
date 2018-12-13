class Board < ApplicationRecord
  RED = 'red'.freeze
  BLUE = 'blue'.freeze
  GREEN = 'green'.freeze
  YELLOW = 'yellow'.freeze
  GREY = 'grey'.freeze

  validates :cells, json: true, allow_blank: false
  validates :goals, json: true, allow_blank: false
  validates :robot_colors, json: true, allow_blank: false

  # Returns the cells in columns instead of rows.
  def column_cells
    cells.transpose
  end

  # Return randomly initialized robot positions.
  def random_robot_positions
    possible_positions = []
    actual_positions = []
    cells.each_with_index do |row, r_idx|
      row.each_with_index do |_, c_idx|
        possible_positions << [r_idx, c_idx] if cells[r_idx][c_idx] < 15
      end
    end

    colors = robot_colors.slice(0, robot_colors.length)
    nr_robots = colors.length
    nr_robots.times do
      pos = possible_positions.delete_at(rand(0...possible_positions.length))
      actual_positions <<
        {
          robot: colors.delete_at(rand(0...colors.length)),
          position: {
            row: pos[0],
            column: pos[1]
          }
        }
    end

    actual_positions
  end

  # Returns a random goal from the board.
  def random_goal
    goals[rand(0...goals.length)]
  end

  # Returns a random goal not in the given goals
  def random_goal_not_in(given_goals)
    remaining = []
    goals.each do |parsed_goal|
      parsed_goal = HashWithIndifferentAccess.new(parsed_goal)
      any = given_goals.any? do |g|
        g = HashWithIndifferentAccess.new(g)
        g[:number] == parsed_goal[:number] && g[:color] == parsed_goal[:color]
      end
      remaining << parsed_goal unless any
    end

    return false if remaining.empty?

    remaining[rand(0...remaining.length)]
  end

  # Checks if the given goal is reached by performing the given
  # moves on the board with the given robot positions.
  def solution?(robot_positions, goal, moves)
    # Clone robot positions because we want to make modifications.
    r_positions = robot_positions.deep_dup
    r_positions.map! { |p| HashWithIndifferentAccess.new(p) }
    goal = HashWithIndifferentAccess.new(goal)

    solution = true
    moves.each do |move|
      if valid_move?(move, r_positions)
        old_pos = r_positions.find { |p| p[:robot] == move[:robot] }
        old_pos[:position][:row] = move[:to][:row]
        old_pos[:position][:column] = move[:to][:column]
      else
        solution = false
        break
      end
    end

    if solution
      # Check if the goal is reached.
      goal_color = goal[:color]
      goal_row = goal[:number] / cells.length
      goal_column = goal[:number] % cells.length

      actual = r_positions.find { |p| p[:robot] == goal_color }
      actual_row = actual[:position][:row]
      actual_column = actual[:position][:column]

      if goal_row == actual_row && goal_column == actual_column
        return r_positions
      end
    end

    false
  end

  def valid_move?(move, robot_positions)
    valid = true

    robot = move[:robot]
    to = move[:to]
    pos = robot_positions.find { |p| p[:robot] == robot }
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
              valid_path_cell?(from_row, idx, :right, robot_positions)
          elsif idx == to_column
            valid &&=
              valid_target_cell?(from_row, idx, :right, robot_positions)
          end
        end
      else
        # Moving left.
        cells[from_row].each_with_index do |cell, idx|
          if idx == from_column
            valid &&= (cell & 8).zero?
          elsif idx > from_column && idx < to_column
            valid &&=
              valid_path_cell?(from_row, idx, :left, robot_positions)
          elsif idx == to_column
            valid &&=
              valid_target_cell?(from_row, idx, :left, robot_positions)
          end
        end
      end
    elsif from_row < to_row
      # Moving down.
      column_cells[from_column].each_with_index do |cell, idx|
        if idx == from_row
          valid &&= (cell & 4).zero?
        elsif idx > from_row && idx < to_row
          valid &&=
            valid_path_cell?(idx, from_column, :down, robot_positions)
        elsif idx == to_row
          valid &&=
            valid_target_cell?(idx, from_column, :down, robot_positions)
        end
      end
    else
      # Moving up.
      column_cells[from_column].each_with_index do |cell, idx|
        if idx == from_row
          valid &&= (cell & 1).zero?
        elsif idx < from_row && idx > to_row
          valid &&=
            valid_path_cell?(idx, from_column, :up, robot_positions)
        elsif idx == to_row
          valid &&=
            valid_target_cell?(idx, from_column, :up, robot_positions)
        end
      end
    end

    valid
  end

  # Is the given cell a reachable path cell between the start and target cell?
  def valid_path_cell?(row, column, direction, robot_positions)
    result = !contains_robot?(row, column, robot_positions)

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
  def contains_robot?(row, column, robot_positions)
    robot_positions.any? do |p|
      p[:position][:row] == row && p[:position][:column] == column
    end
  end

  # Does the next cell in the given direction exist?
  def next_cell_exists?(row, column, direction)
    case direction
    when :up
      (row - 1) >= 0
    when :down
      (row + 1) < cells.length
    when :left
      (column - 1) >= 0
    when :right
      (column + 1) < cells[row].length
    else
      false
    end
  end

  # Is the given cell a valid target cell coming from the given direction.
  def valid_target_cell?(row, column, direction, robot_positions)
    result = !contains_robot?(row, column, robot_positions)
    walls = cells[row][column]

    case direction
    when :up
      result &&= ((walls & 1).positive? && (walls & 4).zero?) ||
                 (next_cell_exists?(row, column, direction) &&
                   contains_robot?(row - 1, column, robot_positions))
    when :down
      result &&= ((walls & 4).positive? && (walls & 1).zero?) ||
                 (next_cell_exists?(row, column, direction) &&
                   contains_robot?(row + 1, column, robot_positions))
    when :left
      result &&= ((walls & 8).positive? && (walls & 2).zero?) ||
                 (next_cell_exists?(row, column, direction) &&
                   contains_robot?(row, column - 1, robot_positions))
    when :right
      result &&= ((walls & 2).positive? && (walls & 8).zero?) ||
                 (next_cell_exists?(row, column, direction) &&
                   contains_robot?(row, column + 1, robot_positions))
    else
      result = false
    end

    result
  end
end
