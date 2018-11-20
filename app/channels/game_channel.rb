# Channel through which games are played.
class GameChannel < ApplicationCable::Channel
  # A user can only subscribe to the channel when he actually
  # joined the room.
  def subscribed
    @room = Room.includes(:owner).find(params[:room])
    reject unless current_user.is_member_of_room?(@room)
    stream_from "game:#{@room.id}"
  end

  # Whenever a user unsubscribes from the channel, he leaves the
  # room.
  def unsubscribed
    @room.remove_user(current_user)

    # If the owner leaves the channel, delete the room and the game.
    if @room.owned_by?(current_user)
      delete_existing_game
      @room.destroy
    end
  end

  # The owner of the room can start a game.
  def start(message)
    if @room.owned_by?(current_user)
      delete_existing_game
      # board = Robots::BoardGenerator.generate
      board = Board.new(cells: [
        [9, 1, 1, 3],
        [8, 0, 0, 2],
        [8, 0, 0, 2],
        [12, 4, 4, 6]
      ].to_json, goals: [
        { number: 0, color: Board::RED },
        { number: 15, color: Board::BLUE }
      ].to_json, robot_colors: [Board::RED, Board::BLUE].to_json)
      board.save
      game = Game.new(
        room: @room,
        open_for_solution: true,
        open_for_moves: false,
        board: board)

      if game.save
        game.start_game!
        data = message.merge(game.board_and_game_data)
        ActionCable.server.broadcast "game:#{@room.id}", data
      else
        logger.error("Could not create new game for room #{@room.id}")
      end
    end
  end

  # Called when a member has a solution in x steps.
  def has_solution_in(message)
    if message['nr_moves']
      nr_moves = message['nr_moves'].to_i
      game = Game.find_by_room_id(@room.id)
      logger.info("Found game #{game.id}")

      game&.evaluate do
        logger.info("Open for solution #{game.open_for_solution?}")
        logger.info("Current best solution #{game.current_best_solution?(nr_moves)}")
        if game.open_for_solution? &&
           game.current_best_solution?(nr_moves)

          data = {
            action: message['action'],
            current_winner: current_user.firstname,
            current_winner_id: current_user.id,
            current_nr_moves: nr_moves
          }

          # Start the game timer if it hasn't been done already.
          attributes = {
            current_nr_moves: nr_moves,
            current_winner: current_user,
            open_for_moves: true }
          unless game.timer_started?
            ScheduleGameThinkTimer.call(game)
            attributes[:timer_started] = true
          end

          game.update!(attributes)

          # Inform subscribers that someone claims to have a solution.
          ActionCable.server.broadcast "game:#{@room.id}", data
        end
      end
    end
  end

  # Actual moves are provided.
  def solution_moves(message)
    if message['moves']
      # Make sure the user providing the moves is the current
      # winner.
      moves = message['moves'].map { |m| HashWithIndifferentAccess.new(m) }
      game = Game.find_by_room_id(@room.id)

      game&.evaluate do
        logger.info("Open for moves: #{game.open_for_moves?}")
        logger.info("Current winner: #{game.current_winner?(current_user)}")
        if game.current_winner?(current_user) && game.open_for_moves?
          logger.info("Solution: #{game.solution?(moves)}")
          if game.solution?(moves)
            logger.info("User #{game.current_winner.firstname} wins!")
            game.close_for_moves!
          end
        end
      end
    end
  end

  private

  # Deletes any existing game in the room.
  def delete_existing_game
    game = Game.find_by_room_id(@room.id)
    game&.delete!
    game&.destroy!
  end
end
