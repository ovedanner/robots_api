class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_from "game_channel"
    debug self
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive

  end
end
