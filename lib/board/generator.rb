module Robots
  # Generates a random new board from existing parts.
  class BoardGenerator

    # Generates a new board.
    def self.generate
      # Initialize all board parts.
      all_board_parts = initialize_parts

      # Randomly select four parts. TODO: make sure only one of each part type exists.
      board_parts = []
      4.times do
        board_parts << all_board_parts.slice!(rand(0...all_board_parts.length))
      end

      # The position of the part in the array indicates
      # its desired position. Rotate parts if needed.
      board_parts.each_with_index do |part, index|
        rotate_times = (index - part.position).abs
        part.rotate_90!(rotate_times)
      end
      board_parts
    end

    # Initializes squares of the board.
    def self.initialize_parts
      parts = []
      parts << BoardPart.new(
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
        BoardPart::RED_GEAR,
        BoardPart::P_1
      ) << BoardPart.new(
        [
          [1, 1, 1, 3, 9, 1, 1, 1],
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
        BoardPart::RED_PLANET,
        BoardPart::P_2
      ) << BoardPart.new(
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
        BoardPart::RED_CIRCLE,
        BoardPart::P_3
      ) << BoardPart.new(
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
        BoardPart::RED_STAR,
        BoardPart::P_4
      )
    end
  end
end
