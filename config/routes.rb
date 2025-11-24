Rails.application.routes.draw do
  
  # ============================================================================
  # AUTHENTICATED ROUTES
  # ============================================================================
  
  authenticated :user do
    root to: "home#dashboard", as: :authenticated_root
    
    # Admin event management (organizers and superadmin)
    resources :events do
      resources :divisions do
        resources :registrations, only: [:new, :create]
        member do
          post :generate_bracket
        end
      end
    end
  end
  
  # ============================================================================
  # PUBLIC ROUTES (No authentication required) - MUST BE FIRST
  # ============================================================================
  
  scope module: :public, as: :public do
    resources :events, only: [:index, :show], path: 'events' do
      resources :divisions, only: [:show], path: 'divisions'
    end
  end
  
  root to: "home#index"
  
  # ============================================================================
  # OTHER ROUTES
  # ============================================================================
  
  devise_for :users
  resources :users, only: [:index, :edit, :update, :destroy]
  resources :teams
  
  resources :athletes do 
    get 'events/:event_id/register', to: 'registrations#new_for_athlete', as: 'register_for_event'
    post 'events/:event_id/register', to: 'registrations#create_for_athlete', as: 'create_registration_for_event'
  end
  
  resources :bouts, only: [:show] do
    member do
      patch :set_winner
    end
    
    collection do
      post :swap
      get :render_slot
      get :render_champion_slot
    end
  end
end