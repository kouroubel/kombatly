class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  
  def index
    # Optional: show preview of upcoming events on homepage
    @upcoming_events = Event.where('start_date >= ?', Date.today).order(:start_date).limit(3)
  end
  
  def dashboard
    # Athlete counts
    if current_user.superadmin?
      @athletes_count = Athlete.count
      @teams_count = Team.count
      @users_count = User.count
      @events_count = Event.count
    elsif current_user.organizer?
      @athletes_count = current_user.administered_team&.athletes&.count || 0
      @teams_count = current_user.administered_team.present? ? 1 : 0
      @events_count = current_user.organized_events.count
    elsif current_user.team_admin?
      @athletes_count = current_user.administered_team&.athletes&.count || 0
      @teams_count = current_user.administered_team.present? ? 1 : 0
      @events_count = 0
    end
    
    # Upcoming events (next 5)
    if current_user.superadmin?
      upcoming = Event.where("start_date >= ?", Date.today)
                      .order(:start_date)
                      .limit(5)
    elsif current_user.organizer?
      upcoming = current_user.organized_events
                             .where("start_date >= ?", Date.today)
                             .order(:start_date)
                             .limit(5)
    else
      upcoming = Event.where("start_date >= ?", Date.today)
                      .order(:start_date)
                      .limit(5)
    end
    
    @upcoming_events = upcoming.map do |event|
      # Global stats (all teams) for the event
      global_regs = event.registrations.includes(:athlete, :division)
      global_total_amount = global_regs.sum { |r| r.division.cost }
      
      global_divisions_summary = global_regs.group_by(&:division).map do |division, div_regs|
        {
          division: division,
          registrations_count: div_regs.size,
          total_amount: div_regs.size * division.cost
        }
      end
      
      # Team-specific stats (if user has a team)
      if current_user.administered_team.present?
        team_regs = global_regs.select { |r| r.athlete.team_id == current_user.administered_team.id }
        team_total_amount = team_regs.sum { |r| r.division.cost }
        
        team_divisions_summary = team_regs.group_by(&:division).map do |division, div_regs|
          {
            division: division,
            registrations_count: div_regs.size,
            total_amount: div_regs.size * division.cost
          }
        end
        
        team_athlete_division_pairs = team_regs.map { |r| { athlete: r.athlete, division: r.division } }
      else
        team_regs = []
        team_total_amount = 0
        team_divisions_summary = []
        team_athlete_division_pairs = []
      end
      
      {
        event: event,
        
        # Global stats
        global_registrations_count: global_regs.size,
        global_total_amount: global_total_amount,
        global_divisions_summary: global_divisions_summary,
        
        # Team stats
        team_registrations_count: team_regs.size,
        team_total_amount: team_total_amount,
        team_divisions_summary: team_divisions_summary,
        team_athlete_division_pairs: team_athlete_division_pairs
      }
    end
  end
end