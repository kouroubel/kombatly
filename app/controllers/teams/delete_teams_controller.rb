# app/controllers/team/teams_controller.rb
module Team
  class TeamsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_team

    def show
      # @team already set
    end

    def edit; end

    def update
      if @team.update(team_params)
        redirect_to team_team_path(@team), notice: "Team updated successfully"
      else
        render :edit
      end
    end

    private

    def set_team
      @team = current_user.team
    end

    def team_params
      params.require(:team).permit(:name)
    end
  end
end
