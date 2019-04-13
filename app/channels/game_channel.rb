# Channel through which games are played.
class GameChannel < ApplicationCable::Channel
  # A user can only subscribe to the channel when he actually
  # joined the room.
  def subscribed
    @room = Room.includes(:owner).find(params[:room])
    reject unless current_user.member_of_room?(@room)
    stream_from "game:#{@room.id}"

    # Inform the other players that someone has joined.
    broadcast_users_changed
  end

  # Whenever a user unsubscribes from the channel, he leaves the
  # room.
  def unsubscribed
    @room.remove_user(current_user)

    # Inform the other players that this player has left.
    broadcast_users_changed
  end

  # Indicates that the current user is ready to play.
  def ready
    @room.user_ready!(current_user)
    broadcast_ready_changed
  end

  # The owner of the room can start a game if all the users are ready.
  def start_new_game
    GameService.start_new_game(@room) if @room.owned_by?(current_user) && @room.all_users_ready?
  end

  # Get the next goal.
  def next_goal
    if @room.owned_by?(current_user) && @room.all_users_ready?
      game = Game.find_by_room_id(@room.id)

      GameService.new(game).next_goal if game.present?
    end
  end

  # Called when a member has a solution in x steps.
  def solution_in(message)
    if message['nr_moves']
      game = Game.find_by_room_id(@room.id)
      nr_moves = message['nr_moves'].to_i

      GameService.new(game).solution_in(current_user, nr_moves) if game.present?
    end
  end

  # Actual moves are provided.
  def solution_moves(message)
    if message['moves']
      game = Game.find_by_room_id(@room.id)
      moves = message['moves'].map { |m| HashWithIndifferentAccess.new(m) }

      GameService.new(game).solution_moves(current_user, moves) if game.present?
    end
  end

  private

  # Signal that the number of players in the room has changed.
  def broadcast_users_changed
    data = {
      action: 'players_changed'
    }
    ActionCable.server.broadcast "game:#{@room.id}", data
  end

  # Signal that the number of ready players in the room has changed.
  def broadcast_ready_changed
    data = {
      action: 'players_ready'
    }
    ActionCable.server.broadcast "game:#{@room.id}", data
  end
end
