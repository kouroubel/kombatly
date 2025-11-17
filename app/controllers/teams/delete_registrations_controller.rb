# app/controllers/team/registrations_controller.rb
module Team
  class RegistrationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_team

    def index
      @registrations = Registration.joins(:athlete).where(athletes: { team_id: @team.id })
    end

    def new
      @athletes = @team.athletes
      @divisions = Division.all # optionally filter by eligibility
      @registration = Registration.new
    end

    def create
      @registration = Registration.new(registration_params)
      if @registration.save
        redirect_to team_team_registrations_path(@team), notice: "Athlete registered"
      else
        render :new
      end
    end

    def destroy
      @registration = Registration.find(params[:id])
      @registration.destroy
      redirect_to team_team_registrations_path(@team), notice: "Registration deleted"
    end

    private

    def set_team
      @team = current_user.team
    end

    def registration_params
      params.require(:registration).permit(:athlete_id, :division_id)
    end
  end
end
