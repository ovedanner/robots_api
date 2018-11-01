# Channel for chatting in a specific room.
class ChatChannel < ApplicationCable::Channel

  # A user can only subscribe to the channel if he is a member
  # of the specified room.
  def subscribed
    @room = Room.find(params[:room])
    reject unless current_user.is_member_of_room?(@room)
    stream_from "chat_#{@room.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # Exchange simple text messages.
  def speak(data)
    ActionCable.server.broadcast "chat_#{@room.id}", data
  end
end
