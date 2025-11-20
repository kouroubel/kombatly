class CreateRegistrations < ActiveRecord::Migration[7.1]
  def change
    create_table :registrations do |t|
      t.references :athlete, null: false, foreign_key: true
      t.references :division, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :registrations, [:athlete_id, :division_id], unique: true
  end
end