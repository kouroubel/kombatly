class HomeController < ApplicationController
  def index
  end
  
  def dashboard
    # Athlete counts
    if current_user.admin?
      @athletes_count = Athlete.count
      @teams_count = Team.count
    elsif current_user.team?
      @athletes_count = current_user.team.athletes.count
      @teams_count = nil
    end

    # Upcoming events (next 5)
    upcoming = Event.where("start_date >= ?", Date.today)
                    .order(:start_date)
                    .limit(5)

    @upcoming_events = upcoming.map do |event|
      # Registrations for this event
      # regs = Registration.joins(:division, :athlete)
      #                   .where(divisions: { event_id: event.id })
      regs = event.registrations.includes(:athlete, :division)

      # Filter by team for team admins
      regs = regs.where(athletes: { team_id: current_user.team.id }) if current_user.team?

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
