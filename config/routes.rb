Rails.application.routes.draw do
  authenticated :user do
    root to: "home#dashboard", as: :authenticated_root
  end
  
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
  
  resources :bouts, only: [:show] do
    member do
      patch :set_winner
    end
    
    collection do
      post :swap
    end
  end
end

# Rails.application.routes.draw do
  
#   # Dynamic root depending on login
#   authenticated :user do
#     root to: "home#dashboard", as: :authenticated_root
#   end
  
#   # Default root for guests
#   root to: "home#index"
  
#   devise_for :users
#   resources :users, only: [:index, :edit, :update, :destroy]
#   resources :teams
#   resources :athletes do 
#     get 'events/:event_id/register', to: 'registrations#new_for_athlete', as: 'register_for_event'
#     post 'events/:event_id/register', to: 'registrations#create_for_athlete', as: 'create_registration_for_event'
#   end
  
#   resources :events do
#     resources :divisions do
#       resources :registrations, only: [:new, :create]
#       member do
#         post :generate_bracket
#       end
#     end
#   end
  
#   resources :bouts, only: [:show] do
#     member do
#       patch :set_winner
#     end
    
#     collection do
#       post :swap
#     end
#   end
# end


# Rails.application.routes.draw do
  
#   # Dynamic root depending on login
#   authenticated :user do
#     root to: "home#dashboard", as: :authenticated_root
#   end

#   # Default root for guests
#   root to: "home#index"

#   devise_for :users
#   resources :users, only: [:index, :edit, :update, :destroy]
#   resources :teams
  
#   resources :athletes do 
#     get 'events/:event_id/register', to: 'registrations#new_for_athlete', as: 'register_for_event'
#     post 'events/:event_id/register', to: 'registrations#create_for_athlete', as: 'create_registration_for_event'
#   end
  
#   resources :events do
#     resources :divisions do
#       resources :registrations, only: [:new, :create]
#       member do
#         post :generate_bracket
#       end
#     end
#   end
  
#   resources :divisions, only: [] do
#     member do
#       post :generate_next_round
#     end
#   end
  
#   resources :bouts, only: [:show] do
#     member do
#       patch :set_winner
#       post :create_point_event
#     end
    
#     collection do
#       post :swap
#     end
#   end

# end
