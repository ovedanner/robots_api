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
      board = Robots::BoardGenerator.generate
      board.save
      game = Game.new(room: @room, board: board)

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

      game&.evaluate do
        if game.open_for_solution? &&
           game.current_best_solution?(nr_moves)

          data = {
            action: message['action'],
            current_winner: game.current_winner.firstname,
            current_winner_id: game.current_winner.id,
            current_nr_moves: nr_moves
          }

          # Start the game timer if it hasn't been done already.
          attributes = {current_nr_moves: nr_moves, current_winner: current_user}
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
        if game.current_winner?(current_user) && game.open_for_moves?
          if game.solution?(moves)
            logger.info("User #{game.current_winner.value} wins!")
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
