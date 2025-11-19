class BoutsController < ApplicationController
  before_action :require_admin, only: [:set_winner, :swap]
  
  def show
    @bout = Bout.find(params[:id])
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
      
      # Place winner in next round (bout already exists)
      result = @bout.division.place_winner_in_next_round(@bout)
      
      render json: { 
        success: true, 
        winner_id: winner_id,
        winner_name: winner.fullname,
        winner_team: winner.team&.name,
        next_bout_id: result[:next_bout]&.id
      }, status: :ok
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