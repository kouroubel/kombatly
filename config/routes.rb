Rails.application.routes.draw do
  
  # Dynamic root depending on login
  authenticated :user do
    root to: "home#dashboard", as: :authenticated_root
  end

  # Default root for guests
  root to: "home#index"

  devise_for :users
  resources :users, only: [:index, :edit, :update, :destroy]
  resources :teams
  
  resources :athletes do 
    get 'events/:event_id/register', to: 'registrations#new_for_athlete', as: 'register_for_event'
    post 'events/:event_id/register', to: 'registrations#create_for_athlete', as: 'create_registration_for_event'
  end
  
  resources :events do
    resources :divisions do
      resources :registrations, only: [:new, :create]
      member do
        post :generate_bracket
      end
    end
  end
  
  
  resources :bouts, only: [] do
    # swap athletes **within this bout**
    patch :swap_athletes, on: :member
  end
  post "/bouts/swap", to: "bouts#swap", as: :swap_bouts


end
