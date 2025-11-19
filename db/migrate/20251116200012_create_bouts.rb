class CreateBouts < ActiveRecord::Migration[7.1]
  def change
    create_table :bouts do |t|
      t.references :division, null: false, foreign_key: true
      t.references :athlete_a, null: true, foreign_key: { to_table: :athletes }  # EXPLICIT null: true
      t.references :athlete_b, null: true, foreign_key: { to_table: :athletes }  # EXPLICIT null: true
      t.references :winner, null: true, foreign_key: { to_table: :athletes }     # EXPLICIT null: true
      t.references :second_place_athlete, null: true, foreign_key: { to_table: :athletes }  # we just need one more column to store the loser of the final that gets the second place. *only* the final bout uses this
      t.integer :round
      t.string  :bout_type, default: "normal"
      t.datetime :scheduled_at
      
      t.timestamps
    end
  end
end