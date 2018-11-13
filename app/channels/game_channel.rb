# Channel through which games are played.
class GameChannel < ApplicationCable::Channel
  # A user can only subscribe to the channel when he actually
  # joined the room.
  def subscribed
    @room = Room.includes(:owner).find(params[:room])
    reject unless current_user.is_member_of_room?(@room)
    stream_from "game_#{@room.id}"
  end

  # Whenever a user unsubscribes from the channel, he leaves the
  # room.
  def unsubscribed
    @room.remove_user(current_user)

    # If the owner leaves the channel, delete the room and the game.
    if @room.owned_by?(current_user)
      game = Game.find_by_room_id(@room.id)
      game&.delete!
      game&.destroy!
      @room.destroy
    end
  end

  # The owner of the room can start a game.
  def start(message)
    if @room.owned_by?(current_user)
      game = Game.new(room_id: @room.id)
      if game.save
        game.start_game

        data = message.merge(
          cells: game.cells.value,
          goals: game.goals.value,
          robot_colors: game.robot_colors.value,
          robot_positions: game.robot_positions.value,
          current_goal: game.current_goal.value
        )

        ActionCable.server.broadcast "game_#{@room.id}", data
      else
        logger.error("Could not create new game for room #{@room.id}")
      end
    end
  end

  # Called when a member has a solution in x steps.
  def has_solution_in(message)
    if message['nr_moves']
      game = Game.find_by_room_id(@room.id)
      if game&.current_best_solution?(current_user, message['nr_moves'].to_i)
        data = {
          action: message['action'],
          current_winner: game.current_winner.value,
          current_nr_moves: game.current_nr_moves.value
        }
        ActionCable.server.broadcast "game_#{@room.id}", data
      end
    end
  end
end
