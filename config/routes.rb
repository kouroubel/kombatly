Rails.application.routes.draw do
  
  # Dynamic root depending on login
  authenticated :user do
    root to: "home#dashboard", as: :authenticated_root
  end

  # Default root for guests
  root to: "home#index"

  devise_for :users
  resources :users, only: [:index, :edit, :update, :destroy]
  
  resources :athletes do 
    get 'events/:event_id/register', to: 'registrations#new_for_athlete', as: 'register_for_event'
    post 'events/:event_id/register', to: 'registrations#create_for_athlete', as: 'create_registration_for_event'
  end
  
  resources :events do
    resources :divisions do
      resources :registrations, only: [:new, :create]
    end
  end
  resources :teams
  
  # Admin-only resources
# namespace :admin do
#     resources :events do
#       resources :divisions
#     end

#     # Add global access for admins to manage athletes and registrations
#     resources :athletes
#     resources :registrations, only: [:index, :new, :create, :destroy]
#   end

  # Team admin dashboard
  # namespace :team do
  #   resources :teams, only: [:show, :edit, :update]
  #   resources :athletes
  #   resources :registrations, only: [:index, :new, :create, :destroy]
  # end



end
