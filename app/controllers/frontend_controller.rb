class FrontendController < ActionController::API
  def index
    html = Redis.current.get('robots:index:current-content')
    render plain: html, content_type: 'text/html'
  end
end
