module Robots
  # Simple board error class.
  class BoardError < StandardError

    def initialize(msg = 'Invalid board')
      super(msg)
    end
  end
end
