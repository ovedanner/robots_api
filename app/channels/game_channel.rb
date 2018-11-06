# Channel through which games are played.
class GameChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.includes(:owner).find(params[:room])
    reject unless current_user.is_member_of_room?(@room)
    stream_from "game_#{@room.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # The owner of the room can start a game.
  def start(message)
    if @room.owned_by?(current_user)
      @game = Robots::Game.new(@room)
      @game.start

      data = message.merge(
        cells: @game.cells.value,
        goals: @game.goals.value,
        robot_colors: @game.robot_colors.value,
        robot_positions: @game.robot_positions.value,
        current_goal: @game.current_goal.value
      )

      ActionCable.server.broadcast "game_#{@room.id}", data
    end
  end

  def solve

  end
end
