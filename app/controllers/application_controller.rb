class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!, unless: :public_page?
  before_action :check_user_approved, unless: :public_page?                 #only the dashboard is visible until assigned a role
  before_action :mailer_set_url_options
  # before_action :configure_permitted_parameters, if: :devise_controller?    #allow fullname on devise registration
  before_action :configure_permitted_parameters, if: -> { devise_controller? && action_name.in?(%w[create update]) }  #allow fullname on devise registration


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
    
    def check_user_approved
      if user_signed_in? && current_user.pending? && !allowed_for_pending?
        redirect_to authenticated_root_path, alert: "Your account is pending approval. An admin will assign your role shortly."
      end
    end
    
    def allowed_for_pending?
      # Allow pending users to access dashboard and edit their profile
      (controller_name == "home" && action_name == "dashboard") || 
      (controller_name == "users" && action_name == "edit")
    end
    
    def public_page?
      (controller_name == "home" && action_name == "index") || devise_controller?
    end
    
    def mailer_set_url_options
      ActionMailer::Base.default_url_options[:host] = request.host_with_port
      # ActionMailer::Base.default_url_options[:protocol] = request.protocol.chomp("://")
    end
  
end
