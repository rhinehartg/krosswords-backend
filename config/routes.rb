Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users
  
  # Puzzle preview route
  get 'puzzle_preview/:id', to: 'puzzle_preview#show', as: 'puzzle_preview'
  
  # AI Puzzle generation routes
  resources :ai_puzzle, only: [:index, :show, :create]
  
  # Daily Challenge generation routes
  resources :daily_challenges, only: [:index, :show, :create]
  
  # Crossword generation and layout routes
  resources :crossword, only: [:show] do
    collection do
      post :generate_ai
      post :generate_layout
    end
    member do
      get :preview
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
