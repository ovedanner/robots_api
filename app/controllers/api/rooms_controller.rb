module Api
  # Rooms controller.
  class RoomsController < ApiController
    # Retrieve all rooms
    def index
      @rooms = Room.all
      render json: @rooms
    end

    # Retrieve all members in the room.
    def members
      @users = User.get_room_members(params.require(:room_id))
      render json: @users
    end

    # Creates a new room
    def create
      @room = Room.new(room_attributes.merge(owner: current_user))
      if @room.save
        render json: @room, status: :created
      else
        render_json_validation_error(@room)
      end
    end

    # View an existing room.
    def show
      @room = Room.find(params.require(:id))
      if @room
        render json: @room
      else
        render json: {}, status: :not_found
      end
    end

    # Updates an existing room.
    def update
      @room = Room.update(params.require(:id), room_attributes)
      if @room.valid?
        render json: @room, status: 200
      else
        render_json_validation_error(@room)
      end
    end

    # The logged in user wants to join the room.
    def join
      if Room.add_user(params.require(:room_id), current_user.id)
        render json: {}, status: 200
      else
        render json: {}, status: :bad_request
      end
    end

    # The logged in user wants to leave the room.
    def leave
      Room.remove_user(params.require(:id), current_user.id)
      render json: {}, status: 200
    end

    # Deletes a room.
    def destroy
      # A user can only destroy his own rooms.
      @room = Room.where(id: params.require(:id), owner: current_user).first

      if @room
        @room.destroy
        render json: {}, status: 200
      else
        render json: {}, status: :not_found
      end
    end

    private

    def room_attributes
      room_params[:attributes] || {}
    end

    def room_params
      params.require(:data).permit(
        :type,
        attributes: %i[name board]
      )
    end
  end
end
