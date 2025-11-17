class ApplicationController < ActionController::Base
  
  before_action :authenticate_user!, except: [:index], if: :home_controller?
  
  #allow fullname on devise registration
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:fullname])
      devise_parameter_sanitizer.permit(:account_update, keys: [:fullname])
    end
  
  private
  
    def admin?
      current_user.role == "admin"
    end
    
    def team_admin?
      current_user.role == "team"
    end

    def home_controller?
      controller_name == "home"
    end
  
end
