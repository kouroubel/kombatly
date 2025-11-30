module Public
  class DivisionsController < ApplicationController
    skip_before_action :authenticate_user!
    
    before_action :set_event
    before_action :set_division
    
    def show
      @bouts_by_round = @division.bouts.order(:round, :id).group_by(&:round)
      @registered_athletes = @division.athletes.includes(:team).order('teams.name, athletes.fullname')
      
      @teams_with_registrations = Team.joins(athletes: :registrations)
                               .where(registrations: { division_id: @division.id })
                               .distinct
                               .includes(:team_admin_role)
    end
    
    private
    
    def set_event
      @event = Event.find(params[:event_id])
    end
    
    def set_division
      @division = @event.divisions.find(params[:id])
    end
  end
end