# class BracketGeneratorService
#   def initialize(division)
#     @division = division
#   end
  
#   def generate
#     athletes = @division.registrations.includes(:athlete).map(&:athlete).shuffle

    
#     return { success: false, error: "Need at least 2 athletes" } if athletes.size < 2

#     ActiveRecord::Base.transaction do
#       # Clear existing bouts
#       @division.bouts.destroy_all
      
#       # Calculate rounds needed
#       total_rounds = Math.log2(next_power_of_2(athletes.size)).ceil
      
#       # Create first round bouts
#       create_first_round(athletes, total_rounds)

#       # Create placeholder bouts for subsequent rounds
#       create_subsequent_rounds(total_rounds)
#     end
#     create_first_round()
#     { success: true }
#   rescue StandardError => e
#     Rails.logger.error("Bracket generation failed: #{e.message}")
#     { success: false, error: e.message }
#   end
  
#   private
  
#   def next_power_of_2(n)
#     2 ** Math.log2(n).ceil
#   end
  
#   def create_first_round(athletes, total_rounds)
#     athletes.each_slice(2).with_index do |pair, index|
#       @division.bouts.create!(
#         athlete_a: pair[0],
#         athlete_b: pair[1],
#         round: 1
#       )
#     end
#   end
  
#   def create_subsequent_rounds(total_rounds)
#     (2..total_rounds).each do |round|
#       bouts_in_round = 2 ** (total_rounds - round)
      
#       bouts_in_round.times do
#         @division.bouts.create!(
#           athlete_a: nil,
#           athlete_b: nil,
#           round: round
#         )
#       end
#     end
#   end
# end