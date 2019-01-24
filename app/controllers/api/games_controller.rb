module Api
  class GamesController < ApiController
    def for_room
      room = Room.includes(:game).find(params[:room_id])
      if room.game && room.open && current_user.member_of_room?(room)
        render json: room.game.board_and_game_data if room.game
      end
    end
  end
end
