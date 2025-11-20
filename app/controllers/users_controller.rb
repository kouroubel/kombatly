class UsersController < ApplicationController
  before_action :require_superadmin
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @pending_users = User.where(role: :pending).order(created_at: :desc)
    @users = User.where.not(role: :pending).order(:role, :email)
  end
  
  def edit
  end

  def update
    # Prevent changing role of superadmin
    if @user.superadmin? && params[:user][:role] != "superadmin"
      redirect_to users_path, alert: "Cannot change the role of a superadmin."
      return
    end

    if @user.update(user_params)
      redirect_to users_path, notice: "User updated successfully."
    else
      render :edit
    end
  end

  def destroy
    if @user.superadmin?
      redirect_to users_path, alert: "Cannot delete a superadmin."
    else
      @user.destroy
      redirect_to users_path, notice: "User deleted."
    end
  end

  private
  
  def set_user
    @user = User.find(params[:id])
  end

  def require_superadmin
    redirect_to root_path, alert: "Access denied" unless current_user&.superadmin?
  end
  
  def user_params
    params.require(:user).permit(:role)
  end
end