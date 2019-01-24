Rails.application.routes.draw do
  namespace :api do
    resources :users, only: %i[create show]
    resources :access_tokens, only: %i[create destroy]
    post '/access_tokens/google', to: 'access_tokens#create_with_google'
    resources :rooms, only: %i[create update show destroy index] do
      get '/members', to: 'rooms#members'
      post '/join', to: 'rooms#join'
      post '/leave', to: 'rooms#leave'
      get '/game', to: 'games#for_room'
    end
    get '/boards/random', to: 'boards#random'
    mount ActionCable.server => '/cable'
  end

  # Catch-all route, will get the appropriate
  # index.html from Redis for the frontend.
  root 'frontend#index'
  get '*path', to: 'frontend#index'
end
