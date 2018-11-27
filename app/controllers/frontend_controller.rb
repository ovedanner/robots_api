class FrontendController < ActionController::API
  def index
    render json: { result: "Test index.html" }
  end
end
