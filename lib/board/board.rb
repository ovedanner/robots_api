module Robots
  # A board, optionally with positions of its robots and a current goal.
  class Board
    attr_accessor :cells, :goals, :robot_colors, :robot_positions

    def initialize(cells, goals, robot_colors, robot_positions = [])
      @cells = cells
      @goals = goals
      @robot_colors = robot_colors
      @robot_positions = robot_positions
    end

    # Creates a new board from the given parts. Expects the
    # parts to be properly rotated for their position.
    def self.create_from_parts(parts = [])
      unless parts.length == 4
        raise Board::BoardError,
              'Invalid number of parts given, needs to be four'
      end

      # Merge the row cells of the first and second pair.
      cells = [
        parts[0].merge_cell_rows(parts[1]),
        parts[1].merge_cell_rows(parts[2])
      ]

      # Simply concatenate the goals.
      goals = []
      parts.each do |part|
        goals << part[:goals]
      end

      # Create a new board and return it.
      new(cells, goals, [])
    end

  end
end
