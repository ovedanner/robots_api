Rails.application.routes.draw do
  namespace :api do
    resources :users, only: %i[create]
    resources :access_tokens, only: %i[create destroy]
    post '/access_tokens/google', to: 'access_tokens#create_with_google'
    resources :rooms, only: %i[create update destroy index] do
      post '/join', to: 'rooms#join'
      post '/leave', to: 'rooms#leave'
    end
    mount ActionCable.server => '/cable'
  end
end
