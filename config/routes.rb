Rails.application.routes.draw do
  namespace :api do
    resources :users, only: %i[index show]
    resources :access_tokens, only: %i[create destroy]
  end
end
