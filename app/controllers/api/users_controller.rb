module Api
  # Users controller
  class UsersController < ApiController
    skip_before_action :require_authentication, only: :create

    # Create a new user
    def create
      @user = User.new(user_attributes)
      if @user.save
        created(@user)
      else
        validation_errors(@user)
      end
    end

    # Retrieves a user. Currently you can only retrieve your own
    # user.
    def show
      user_id = params.require(:id).to_i

      if user_id != current_user.id
        bad_request
      else
        @user = User.find(user_id)
        if @user
          success(body: @user)
        else
          not_found
        end
      end
    end

    private

    def user_attributes
      user_params[:attributes] || {}
    end

    def user_params
      params.require(:data).permit(
        :type,
        attributes: %i[email password password_confirmation firstname]
      )
    end
  end
end
