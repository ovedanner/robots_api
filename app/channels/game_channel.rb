# Channel through which games are played.
class GameChannel < ApplicationCable::Channel
  # A user can only subscribe to the channel when he actually
  # joined the room.
  def subscribed
    @room = Room.includes(:owner).find(params[:room])
    reject unless current_user.member_of_room?(@room)
    stream_from "game:#{@room.id}"

    # Inform the other players that someone has joined.
    broadcast_nr_players
  end

  # Whenever a user unsubscribes from the channel, he leaves the
  # room.
  def unsubscribed
    @room.remove_user(current_user)

    # Inform the other players that this player has left.
    broadcast_nr_players
  end

  # Indicates that the current user is ready to play.
  def ready
    @room.user_ready!(current_user)
    broadcast_readiness
  end

  # The owner of the room can start a game if all the users are ready.
  def start_new_game
    @room.start_new_game! if @room.owned_by?(current_user) && @room.users_ready?
  end

  # Get the next goal.
  def next_goal
    if @room.owned_by?(current_user) && @room.users_ready?
      game = Game.find_by_room_id(@room.id)
      game&.next_goal!
    end
  end

  # Called when a member has a solution in x steps.
  def solution_in(message)
    if message['nr_moves']
      game = Game.find_by_room_id(@room.id)
      nr_moves = message['nr_moves'].to_i

      game.solution_in!(current_user, nr_moves) if game
    end
  end

  # Actual moves are provided.
  def solution_moves(message)
    if message['moves']
      game = Game.find_by_room_id(@room.id)
      moves = message['moves'].map { |m| HashWithIndifferentAccess.new(m) }
      game&.solution_moves(current_user, moves)
    end
  end

  private

  # Broadcast the total number of players in the room.
  def broadcast_nr_players
    data = {
      action: 'players',
      total: @room.room_users.size,
    }
    ActionCable.server.broadcast "game:#{@room.id}", data
  end

  # Broadcast player readiness state for the room.
  def broadcast_readiness
    data = {
      action: 'players_ready',
      total: @room.room_users.count(&:ready?),
    }
    ActionCable.server.broadcast "game:#{@room.id}", data
  end
end
