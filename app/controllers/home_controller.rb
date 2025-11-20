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
      @teams_count = current_user.administered_team ? 1 : 0 # They have one team or no team
      @events_count = current_user.organized_events.count
    elsif current_user.team_admin?
      @athletes_count = current_user.administered_team&.athletes&.count || 0
      @teams_count = 1 # They have one team
      @events_count = 0 # Team admins don't organize events
    end
    
    # Upcoming events (next 5)
    if current_user.superadmin?
      # Superadmin sees all events
      upcoming = Event.where("start_date >= ?", Date.today)
                      .order(:start_date)
                      .limit(5)
    elsif current_user.organizer?
      # Organizers see their own events
      upcoming = current_user.organized_events
                             .where("start_date >= ?", Date.today)
                             .order(:start_date)
                             .limit(5)
    else
      # Team admins see all events (to register their athletes)
      upcoming = Event.where("start_date >= ?", Date.today)
                      .order(:start_date)
                      .limit(5)
    end
    
    @upcoming_events = upcoming.map do |event|
      # Registrations for this event
      regs = event.registrations.includes(:athlete, :division)
      # ALWAYS filter by team for non-superadmins (if they have a team)
      if !current_user.superadmin?
        if current_user.administered_team.present?
          regs = regs.where(athletes: { team_id: current_user.administered_team.id })
        else
          regs = regs.none
        end
      end
      # Total fees for this event
      total_amount = regs.sum { |r| r.division.cost }
      
      # Per-division summary
      divisions_summary = regs.group_by(&:division).map do |division, div_regs|
        {
          division: division,
          registrations_count: div_regs.size,
          total_amount: div_regs.size * division.cost
        }
      end
      
      # Athlete + division mapping for listing
      athlete_division_pairs = regs.map { |r| { athlete: r.athlete, division: r.division } }
      
      {
        event: event,
        registrations_count: regs.size,
        total_amount: total_amount,
        divisions_summary: divisions_summary,
        athlete_division_pairs: athlete_division_pairs
      }
    end
  end
end