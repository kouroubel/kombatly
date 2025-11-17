class CreatePointEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :point_events do |t|
      t.references :bout, null: false, foreign_key: true
      t.references :athlete, null: false, foreign_key: true
      t.string :technique
      t.integer :points
      t.datetime :scored_at

      t.timestamps
    end
  end
end
