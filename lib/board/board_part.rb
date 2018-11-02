module Board
  # A board consists of four parts that can be rotated.
  class BoardPart
    # Different board part types
    RED_GEAR = 1
    RED_PLANET = 2
    RED_CIRCLE = 3
    RED_STAR = 4

    # Different part positions.
    P_1 = 0
    P_2 = 1
    P_3 = 2
    P_4 = 3

    attr_accessor :cells, :goals, :type, :position

    def initialize(cells, goals, type, position)
      @cells = cells
      @goals = goals
      @type = type
      @position = position
    end

    # Rotates the part by 90 degrees clockwise a given number
    # of times.
    def rotate_90!(times)
      nr_rows = cells.length
      times.times do
        (0...(nr_rows / 2)).each do |layer|
          first = layer
          last = nr_rows - 1 - layer
          (first...last).each do |i|
            offset = i - first

            # Save the top.
            top = cells[first][i]

            # left -> top.
            cells[first][i] = cells[last - offset][first]

            # bottom -> left.
            cells[last - offset][first] = cells[last][last - offset]

            # right -> bottom.
            cells[last][last - offset] = cells[i][last]

            # top -> right.
            cells[i][last] = top
          end
        end

        # Also update the positions of the goals.
        goals.each do |goal|
          rotate_goal_90!(goal)
        end
      end
    end

    # Rotates the given goal by 90 degrees clockwise. This
    # simply means updating its number.
    def rotate_goal_90!(goal)
      # row becomes column
      # column becomes length - row
      goal_row = goal[:number] / nr_rows
      goal_column = goal[:number] % nr_rows

      new_goal_row = goal_column
      new_goal_column = nr_rows - 1 - goal_row

      goal[:number] = (new_goal_row * nr_rows) + new_goal_column
    end

    # Makes for easier part checking.
    def to_s
      result = ''
      cells.each do |row|
        result.concat(row.join(', '), "\n")
      end

      result
    end
  end

  # Merges the rows of the given part with those of this part.
  def merge_cell_rows(other_part)
    result = []

    cells.length.times do |row|
      result << cells[row].concat(other_part.cells[row])
    end

    result
  end
end
