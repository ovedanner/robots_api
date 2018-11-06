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
  end
end
