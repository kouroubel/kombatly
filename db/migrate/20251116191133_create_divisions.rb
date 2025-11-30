class CreateDivisions < ActiveRecord::Migration[7.1]
  def change
    create_table :divisions do |t|
      t.string :name, null: false
      t.string :sex, null: false
      t.integer :min_age, null: false
      t.integer :max_age, null: false
      t.decimal :min_weight, precision: 4, scale: 1
      t.decimal :max_weight, precision: 4, scale: 1
      t.integer :min_rank, null: false
      t.integer :max_rank, null: false
      t.decimal :cost, null: false
      t.string :court
      t.text :description
      
      t.references :event, null: false, foreign_key: true

      t.timestamps
    end
  end
end