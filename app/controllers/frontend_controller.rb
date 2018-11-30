class FrontendController < ActionController::API
  def index
    html = Redis.new.get('robots:index:current-content')
    render text: html
  end
end
