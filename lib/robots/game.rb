module Robots
  # A game is a board in a particular state.
  class Game
    include Redis::Objects

    # Used in the key to store this game in Redis.
    attr_reader :id

    # Initializes a game for the given room, optionally with
    # a given board.
    def initialize(room, board = Robots::BoardGenerator.generate)
      @id = room.id

      # Clear any existing values.
      reset

      board.cells.each do |row|
        cells << row
      end

      board.goals.each do |goal|
        goals << goal
      end

      board.robot_colors.each do |color|
        robot_colors << color
      end
    end

    list :cells, marshal: true
    list :goals, marshal: true
    list :robot_colors, marshal: true
    list :robot_positions, marshal: true
    list :completed_goals
    list :current_solution, marshal: true
    value :current_goal, marshal: true
    value :start
    lock :solve

    # Starts the game by randomly initializing the robots and setting a current goal.
    def start_game
      initialize_robots
      initialize_goal
      self.start = true
    end

    private

    # Randomly initialize robots.
    def initialize_robots
      possible_positions = []
      cells.each_with_index do |row, r_idx|
        row.each_with_index do |_, c_idx|
          possible_positions << [r_idx, c_idx] if cells[r_idx][c_idx] < 15
        end
      end
      nr_robots = robot_colors.length
      nr_robots.times do
        robot_positions <<
          possible_positions.delete_at(rand(0...possible_positions.length))
      end
    end

    # Randomly sets the current goal.
    def initialize_goal
      self.current_goal = goals[rand(0...goals.length)]
    end

    # Reset properties.
    def reset
      %i[cells goals robot_colors robot_positions completed_goals].each do |prop|
        send(prop).send(:clear)
      end

      self.current_goal = nil
      self.start = false
    end
  end
end
