module Robots
  module Error
    # Simple game error class.
    class GameError < StandardError
      def initialize(msg = 'Invalid game')
        super(msg)
      end
    end
  end
end
