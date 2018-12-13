# Channel through which games are played.
class GameChannel < ApplicationCable::Channel
  # A user can only subscribe to the channel when he actually
  # joined the room.
  def subscribed
    @room = Room.includes(:owner).find(params[:room])
    reject unless current_user.member_of_room?(@room)
    stream_from "game:#{@room.id}"
  end

  # Whenever a user unsubscribes from the channel, he leaves the
  # room.
  def unsubscribed
    @room.remove_user(current_user)

    # Stop any pending timer.
    @moves_timer.cancel if @moves_timer&.pending?

    # If the owner leaves the channel, delete the room and the game.
    if @room.owned_by?(current_user)
      game = Game.find_by_room_id(@room.id)
      game&.destroy
      @room.destroy
    end
  end

  # The owner of the room can start a game.
  def start_new_game
    @room.start_new_game! if @room.owned_by?(current_user)
  end

  # Get the next goal.
  def next_goal
    if @room.owned_by?(current_user)
      game = Game.find_by_room_id(@room.id)
      game&.next_goal!
    end
  end

  # Called when a member has a solution in x steps.
  def solution_in(message)
    if message['nr_moves']
      game = Game.find_by_room_id(@room.id)
      nr_moves = message['nr_moves'].to_i

      # Store the returned timer (only applicable for the user
      # that provides the moves first).
      @moves_timer = game.solution_in!(current_user, nr_moves) if game
    end
  end

  # Actual moves are provided.
  def solution_moves(message)
    if message['moves']
      game = Game.find_by_room_id(@room.id)
      if game&.solution_moves(current_user, message['moves'])
        # Stop the moves timer if it's running.
        logger.info(@moves_timer)
        logger.info("Timer is running: #{@moves_timer&.pending?}")
        @moves_timer.cancel if @moves_timer&.pending?
      end
    end
  end
end
