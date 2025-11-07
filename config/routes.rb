Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users
  
  # API Routes
  namespace :api do
    # Authentication
    post 'auth/login', to: 'auth#login'
    post 'auth/register', to: 'auth#register'
    post 'auth/logout', to: 'auth#logout'
    post 'auth/refresh', to: 'auth#refresh'
    get 'auth/me', to: 'auth#me'
    
    # Health check
    get 'health', to: 'health#show'
    
    # Puzzles
    resources :puzzles, only: [:index, :show, :create, :update, :destroy]
    
    # Game Sessions
    resources :game_sessions, only: [:index, :show, :create, :update, :destroy]
    get 'game_sessions/puzzle/:puzzle_id', to: 'game_sessions#show_or_create'
    put 'game_sessions/:id/complete', to: 'game_sessions#complete'
    
    # Users
    get 'users/profile', to: 'users#profile'
    put 'users/profile', to: 'users#update_profile'
    
    # AI Puzzle generation
    resources :ai_puzzle, only: [:index, :show, :create]
  end
  
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
