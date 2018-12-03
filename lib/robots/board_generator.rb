module Robots
  # Generates a random new board from existing parts.
  class BoardGenerator
    # Generates a new board.
    def self.generate
      # Get all board parts.
      all_board_parts = board_parts

      # Randomly select four of them. TODO: make sure only one of each part type exists.
      parts = []
      indices = (0...4).to_a.shuffle
      4.times do
        parts << all_board_parts[indices.shift]
      end

      # The position of the part in the array indicates
      # its desired position. Rotate parts if needed.
      parts.each_with_index do |part, index|
        next unless part.position != index
        rotate_times = (index - part.position) % 4
        part.rotate_90!(rotate_times)
      end

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

      parts.each_with_index do |part, idx|
        part.goals.each do |goal|
          goal_row = goal[:number] / part_size
          goal_column = goal[:number] % part_size

          goal_row += part_size if [2, 3].include?(idx)
          goal_column += part_size if [1, 2].include?(idx)

          goal[:number] = (goal_row * target_size) + goal_column
        end
      end

      # Merge the row cells of the first and second pair.
      top_rows = parts[0].merge_cell_rows(parts[1])
      bottom_rows = parts[3].merge_cell_rows(parts[2])
      cells = top_rows.concat(bottom_rows)

      # Simply concatenate the goals.
      goals = []
      robot_colors = []
      parts.each do |part|
        goals.concat(part.goals)
        robot_colors.concat(part.goals.map { |g| g[:color] })
      end

      # Create a new board and return it.
      Board.new(
        cells: cells.to_json,
        goals: goals.to_json,
        robot_colors: robot_colors.uniq.to_json)
    end

    # Initializes the static squares of the board.
    def self.board_parts
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
          { number: 21, color: Board::BLUE },
          { number: 34, color: Board::GREEN },
          { number: 47, color: Board::RED },
          { number: 49, color: Board::YELLOW }
        ],
        Robots::BoardPart::RED_GEAR,
        Robots::BoardPart::P_1
      ) << Robots::BoardPart.new(
        [
          [1, 1, 1, 3, 9, 1, 1, 3],
          [0, 0, 0, 0, 0, 0, 0, 2],
          [0, 0, 0, 6, 8, 4, 0, 2],
          [0, 0, 0, 1, 0, 3, 0, 2],
          [0, 2, 12, 0, 4, 0, 0, 2],
          [0, 0, 1, 2, 9, 0, 0, 6],
          [4, 0, 0, 0, 0, 0, 0, 3],
          [15, 8, 0, 0, 0, 0, 0, 2]
        ],
        [
          { number: 19, color: Board::RED },
          { number: 29, color: Board::YELLOW },
          { number: 34, color: Board::GREEN },
          { number: 44, color: Board::BLUE }
        ],
        Robots::BoardPart::RED_PLANET,
        Robots::BoardPart::P_2
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
          { number: 14, color: Board::YELLOW },
          { number: 17, color: Board::GREEN },
          { number: 28, color: Board::RED },
          { number: 40, color: Board::GREY },
          { number: 50, color: Board::BLUE }
        ],
        Robots::BoardPart::RED_STAR,
        Robots::BoardPart::P_3
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
          { number: 9, color: Board::YELLOW },
          { number: 13, color: Board::BLUE },
          { number: 38, color: Board::RED },
          { number: 50, color: Board::GREEN }
        ],
        Robots::BoardPart::RED_CIRCLE,
        Robots::BoardPart::P_4
      )
      parts
    end
  end
end
