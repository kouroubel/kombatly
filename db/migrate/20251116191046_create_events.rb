class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.text :location
      t.text :description
      t.references :organizer, null: true, foreign_key: { to_table: :users }
      
      t.timestamps
    end
  end
end