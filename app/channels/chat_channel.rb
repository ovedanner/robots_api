# Channel for chatting in a specific room.
class ChatChannel < ApplicationCable::Channel
  # A user can only subscribe to the channel if he is a member
  # of the specified room.
  def subscribed
    @room = Room.find(params[:room])
    reject unless current_user.member_of_room?(@room)
    stream_from "chat:#{@room.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # Exchange simple text messages.
  def speak(message)
    data = message.merge(
      author: current_user.firstname,
      author_id: current_user.id,
    )

    ActionCable.server.broadcast "chat:#{@room.id}", data
  end
end
