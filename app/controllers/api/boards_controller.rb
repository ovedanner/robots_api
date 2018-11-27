module Api
  class BoardsController < ApiController
    skip_before_action :require_authentication, only: :random

    # Retrieves a random board.
    def random
      @board = Robots::BoardGenerator.generate
      success(@board)
    end
  end
end
