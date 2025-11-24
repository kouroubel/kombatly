class BoutsController < ApplicationController
  before_action :require_admin, only: [:set_winner, :swap]
  
  def show
    @bout = Bout.find(params[:id])
    
    respond_to do |format|
      format.html
      format.json do
        render json: {
          id: @bout.id,
          bout_type: @bout.bout_type,
          athlete_a: @bout.athlete_a ? {
            id: @bout.athlete_a.id,
            fullname: @bout.athlete_a.fullname,
            team_name: @bout.athlete_a.team&.name
          } : nil,
          athlete_b: @bout.athlete_b ? {
            id: @bout.athlete_b.id,
            fullname: @bout.athlete_b.fullname,
            team_name: @bout.athlete_b.team&.name
          } : nil,
          loser: @bout.loser ? {  # Changed from second_place_athlete
            id: @bout.loser.id,
            fullname: @bout.loser.fullname,
            team_name: @bout.loser.team&.name
          } : nil,
          winner_id: @bout.winner_id
        }
      end
    end
  end
  
  def render_slot
    athlete = Athlete.find_by(id: params[:athlete_id])
    show_medal = params[:show_medal] == 'true'
    medal_color = params[:medal_color]
    show_trophy = params[:show_trophy] == 'true'
    place_badge = nil
    corner_badge = nil
    
    if params[:place_badge].present?
      place_badge = {
        class: params[:place_badge][:class],
        style: params[:place_badge][:style],
        text: params[:place_badge][:text]
      }
    end
    
    if params[:corner_badge].present?
      corner_badge = {
        class: params[:corner_badge][:class],
        style: params[:corner_badge][:style],
        text: params[:corner_badge][:text]
      }
    end
    
    render partial: 'divisions/athlete_slot_content', 
           locals: { 
             athlete: athlete, 
             show_medal: show_medal,
             medal_color: medal_color,
             show_trophy: show_trophy,
             place_badge: place_badge,
             corner_badge: corner_badge
           }
  end

  def render_champion_slot
    athlete = Athlete.find_by(id: params[:athlete_id])
    medal_color = params[:medal_color]
    medal_icon = params[:medal_icon] || 'medal'
    badge_class = params[:badge_class]
    badge_style = params[:badge_style]
    badge_text = params[:badge_text]
    
    render partial: 'divisions/champion_slot_content', 
           locals: { 
             athlete: athlete,
             medal_color: medal_color,
             medal_icon: medal_icon,
             badge_class: badge_class,
             badge_style: badge_style,
             badge_text: badge_text
           }
  end
  
  def set_winner
    @bout = Bout.find(params[:id])
    winner_id = params[:winner_id]
    
    unless current_user&.admin?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end
    
    if winner_id.to_i == @bout.athlete_a_id || winner_id.to_i == @bout.athlete_b_id
      @bout.update!(winner_id: winner_id)
      
      winner = Athlete.find(winner_id)
      
      # Place winner in next round
      result = @bout.division.place_winner_in_next_round(@bout)
      
      # Check if this is a semi-final
      final_bout = @bout.division.bouts.find_by(bout_type: "final")
      is_semi_final = (@bout.round == final_bout.round - 1) if final_bout
      
      response_data = { 
        success: true, 
        winner_id: winner_id,
        winner_name: winner.fullname,
        winner_team: winner.team&.name,
        bout_type: result[:bout_type],
        next_bout_id: result[:next_bout]&.id
      }
      
      # For semi-finals, also handle loser
      if is_semi_final
        loser_result = @bout.division.place_loser_in_consolation(@bout)
        
        if loser_result[:success]
          loser_id = winner_id == @bout.athlete_a_id ? @bout.athlete_b_id : @bout.athlete_a_id
          loser = Athlete.find(loser_id)
          
          response_data[:consolation_bout_id] = loser_result[:consolation_bout]&.id
          response_data[:loser_id] = loser_id
          response_data[:loser_name] = loser.fullname
          response_data[:loser_team] = loser.team&.name
          response_data[:is_semi_final] = true
        end
      end
      
      render json: response_data, status: :ok
    else
      render json: { error: "Invalid winner" }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Set winner error: #{e.message}")
    render json: { error: e.message }, status: :internal_server_error
  end
  
  def swap
    source = params[:source]
    target = params[:target]

    unless valid_swap_params?(source, target)
      render json: { error: "Invalid parameters" }, status: :unprocessable_entity
      return
    end

    source_bout = Bout.find_by(id: source[:bout_id])
    target_bout = Bout.find_by(id: target[:bout_id])

    unless source_bout && target_bout
      render json: { error: "Bout not found" }, status: :not_found
      return
    end

    ActiveRecord::Base.transaction do
      swap_athletes(source_bout, target_bout, source, target)
    end

    render json: { 
      success: true, 
      message: "Athletes swapped successfully"
    }, status: :ok

  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Swap error: #{e.message}")
    render json: { error: "An error occurred" }, status: :internal_server_error
  end

  private

  def valid_swap_params?(source, target)
    return false unless source && target
    return false unless source[:bout_id] && source[:slot]
    return false unless target[:bout_id] && target[:slot]
    return false unless ["a", "b"].include?(source[:slot])
    return false unless ["a", "b"].include?(target[:slot])
    true
  end

  def swap_athletes(source_bout, target_bout, source_params, target_params)
    source_slot = source_params[:slot]
    target_slot = target_params[:slot]

    source_athlete_id = source_slot == "a" ? source_bout.athlete_a_id : source_bout.athlete_b_id
    target_athlete_id = target_slot == "a" ? target_bout.athlete_a_id : target_bout.athlete_b_id

    if source_bout.id == target_bout.id
      source_bout.update!(
        athlete_a_id: target_athlete_id,
        athlete_b_id: source_athlete_id
      )
    else
      if source_slot == "a"
        source_bout.update!(athlete_a_id: target_athlete_id)
      else
        source_bout.update!(athlete_b_id: target_athlete_id)
      end

      if target_slot == "a"
        target_bout.update!(athlete_a_id: source_athlete_id)
      else
        target_bout.update!(athlete_b_id: source_athlete_id)
      end
    end
  end

  def require_admin
    unless current_user&.admin?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end