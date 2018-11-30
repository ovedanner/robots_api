class FrontendController < ActionController::API
  def index
    html = Redis.current.get('robots:index:current-content')
    render text: html
  end
end
