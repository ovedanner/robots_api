module Api
  # Users controller
  class UsersController < ApiController
    skip_before_action :require_authentication, only: :create

    # Create a new user
    def create
      @user = User.new(user_attributes)
      if @user.save
        render json: @user, status: :created
      else
        render_json_validation_error(@user)
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
