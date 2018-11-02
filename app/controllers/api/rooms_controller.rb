module Api
  # Rooms controller.
  class RoomsController < ApiController
    # Retrieve all rooms
    def index
      @rooms = Room.includes(:owner).all
      render json: @rooms, include: [:owner]
    end

    # Retrieve all members in the room.
    def members
      @room = Room.find(params.require(:room_id))
      if @room
        render json: @room.members
      else
        render json: {}, status: :not_found
      end
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
      @room = Room.includes(:owner).find(params.require(:id))
      if @room
        render json: @room, include: [:owner]
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
      @room = Room.find(params.require(:room_id))
      if @room&.add_user(current_user)
        render json: {}, status: 200
      else
        render json: {}, status: :not_found
      end
    end

    # The logged in user wants to leave the room.
    def leave
      @room = Room.find(params.require(:room_id))
      if @room&.remove_user(current_user)
        render json: {}, status: 200
      else
        render json: {}, status: :not_found
      end
    end

    # Deletes a room.
    def destroy
      # A user can only destroy his own rooms.
      @room = Room.includes(:owner).find(params.require(:id))

      if @room && @room.owner.id == current_user.id
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
