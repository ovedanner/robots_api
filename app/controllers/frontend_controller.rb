class FrontendController < ActionController::API
  def index
    render json: { result: "Test index.html and it has been changed! larpiedur" }
  end
end
