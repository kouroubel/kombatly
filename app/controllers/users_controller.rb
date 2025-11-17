class UsersController < ApplicationController

  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = User.order(:id)
  end
  
  def edit
  end

  def update
    # Prevent changing role of the first admin
    if @user.role == "admin" && params[:user][:role] != "admin"
      redirect_to users_path, alert: "Cannot change the role of an admin."
      return
    end

    if @user.update(user_params)
      redirect_to users_path, notice: "User updated successfully."
    else
      render :edit
    end
  end


  def destroy
    if @user.role != "admin"
      @user.destroy
      redirect_to users_path, notice: "User deleted."
    else
      redirect_to users_path, alert: "Cannot delete an admin."
    end
  end


  private
  
  def set_user
    @user = User.find(params[:id])
  end

  def require_admin
    redirect_to root_path, alert: "Access denied" unless current_user.admin?
  end
  
  def user_params
    params.require(:user).permit(:role)
  end
end
