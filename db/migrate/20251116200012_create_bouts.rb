class CreateBouts < ActiveRecord::Migration[7.1]
  def change
    create_table :bouts do |t|
      t.references :division, null: false, foreign_key: true
      t.references :athlete_a, null: true, foreign_key: { to_table: :athletes }
      t.references :athlete_b, null: true, foreign_key: { to_table: :athletes }
      t.references :winner, null: true, foreign_key: { to_table: :athletes }
      t.references :loser, null: true, foreign_key: { to_table: :athletes }
      t.integer :round
      t.string  :bout_type, default: "normal"
      t.datetime :scheduled_at
      
      t.timestamps
    end
  end
end