module Robots
  # Generates a random new board from existing parts.
  class BoardGenerator
    # Generates a new board.
    def self.generate
      # Get all board parts.
      all_board_parts = get_board_parts

      # Randomly select four of them. TODO: make sure only one of each part type exists.
      parts = all_board_parts
      # indices = (0...4).to_a
      # 4.times do
      #   index = indices.slice!(rand(0...indices.length))
      #   parts << all_board_parts[index]
      # end

      # The position of the part in the array indicates
      # its desired position. Rotate parts if needed.
      # parts.each_with_index do |part, index|
      #
      #   rotate_times = (index - part.position).abs
      #   part.rotate_90!(rotate_times)
      # end

      # Stitch the parts together and update the goal
      # numbers to reflect this.
      generate_from_parts(parts)
    end

    # Stitches together four board parts of the same size
    # and returns a new board.
    def self.generate_from_parts(parts)
      unless parts.length == 4
        raise Robots::BoardError,
              'Invalid number of parts given, needs to be four'
      end

      # Only the goals of the first part have the correct number.
      # The others need to be adjusted for the new number of rows
      # and columns.
      part_size = parts[0].cells.length
      target_size = part_size * 2

      # The goals of the second part are in a different column.
      part_two = parts[1]
      part_two.goals.each do |goal|
        goal_row = goal[:number] / part_size
        goal_column = goal[:number] % part_size

        new_goal_column = goal_column + part_size
        goal[:number] = (goal_row * target_size) + new_goal_column
      end

      # The goals the of third part are in a different row.
      part_three = parts[2]
      part_three.goals.each do |goal|
        goal_row = goal[:number] / part_size
        goal_column = goal[:number] % part_size

        new_goal_row = goal_row + part_size
        goal[:number] = (new_goal_row * target_size) + goal_column
      end

      # The goals of the last part are in both a different column and
      # different row.
      part_four = parts[3]
      part_four.goals.each do |goal|
        goal_row = goal[:number] / part_size
        goal_column = goal[:number] % part_size

        new_goal_row = goal_row + part_size
        new_goal_column = goal_column + part_size
        goal[:number] = (new_goal_row * target_size) + new_goal_column
      end

      # Merge the row cells of the first and second pair.
      top_rows = parts[0].merge_cell_rows(parts[1])
      bottom_rows = parts[2].merge_cell_rows(parts[3])
      cells = top_rows.concat(bottom_rows)

      # Simply concatenate the goals.
      goals = []
      robot_colors = []
      parts.each do |part|
        goals.concat(part.goals)
        robot_colors.concat(part.goals.map { |g| g[:color] })
      end

      # Create a new board and return it.
      Board.new(cells: cells, goals: goals, robot_colors: robot_colors.uniq)
    end

    # Initializes the static squares of the board.
    def self.get_board_parts
      parts = []
      parts << Robots::BoardPart.new(
        [
          [9, 1, 1, 3, 9, 1, 1, 1],
          [8, 0, 0, 0, 0, 0, 0, 0],
          [8, 0, 0, 0, 0, 6, 8, 0],
          [8, 0, 4, 0, 0, 1, 0, 0],
          [12, 0, 3, 8, 0, 0, 0, 0],
          [9, 4, 0, 0, 0, 0, 2, 12],
          [10, 9, 0, 0, 0, 0, 0, 5],
          [8, 0, 0, 0, 0, 0, 2, 15]
        ],
        [
          { number: 21, color: :blue },
          { number: 34, color: :green },
          { number: 47, color: :red },
          { number: 49, color: :yellow }
        ],
        Robots::BoardPart::RED_GEAR,
        Robots::BoardPart::P_1
      ) << Robots::BoardPart.new(
        [
          [1, 1, 1, 3, 9, 1, 1, 3],
          [0, 0, 0, 0, 0, 0, 0, 2],
          [0, 0, 0, 6, 8, 4, 0, 2],
          [0, 0, 0, 1, 0, 3, 8, 2],
          [0, 2, 12, 0, 4, 0, 0, 2],
          [0, 0, 1, 2, 9, 0, 9, 6],
          [4, 0, 0, 0, 0, 0, 0, 3],
          [15, 8, 0, 0, 0, 0, 0, 2]
        ],
        [
          { number: 19, color: :red },
          { number: 29, color: :yellow },
          { number: 34, color: :green },
          { number: 44, color: :blue }
        ],
        Robots::BoardPart::RED_PLANET,
        Robots::BoardPart::P_2
      ) << Robots::BoardPart.new(
        [
          [8, 4, 0, 0, 0, 4, 2, 15],
          [8, 3, 8, 0, 2, 9, 0, 1],
          [12, 0, 0, 0, 0, 0, 0, 0],
          [9, 0, 0, 0, 0, 0, 0, 0],
          [8, 0, 0, 0, 0, 0, 6, 8],
          [8, 0, 0, 0, 0, 0, 1, 0],
          [8, 2, 12, 0, 0, 0, 0, 0],
          [12, 4, 5, 4, 4, 6, 12, 4]
        ],
        [
          { number: 9, color: :yellow },
          { number: 13, color: :blue },
          { number: 38, color: :red },
          { number: 50, color: :green }
        ],
        Robots::BoardPart::RED_CIRCLE,
        Robots::BoardPart::P_3
      ) << Robots::BoardPart.new(
        [
          [15, 8, 0, 0, 0, 0, 0, 2],
          [1, 0, 0, 0, 0, 2, 12, 2],
          [0, 6, 8, 0, 4, 0, 1, 2],
          [0, 1, 0, 2, 9, 0, 0, 6],
          [4, 0, 0, 0, 0, 0, 0, 3],
          [9, 0, 4, 0, 0, 0, 0, 2],
          [0, 0, 3, 8, 0, 0, 0, 2],
          [4, 4, 4, 4, 6, 12, 4, 6]
        ],
        [
          { number: 14, color: :yellow },
          { number: 17, color: :green },
          { number: 28, color: :red },
          { number: 40, color: :grey },
          { number: 50, color: :blue }
        ],
        Robots::BoardPart::RED_STAR,
        Robots::BoardPart::P_4
      )
      parts
    end
  end
end
