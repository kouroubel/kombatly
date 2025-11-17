class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.text :location
      t.text :description
      
      t.timestamps
    end
  end
end
