class CreateDivisions < ActiveRecord::Migration[7.1]
  def change
    create_table :divisions do |t|
      t.string :name, null: false
      t.references :event, null: false, foreign_key: true
      t.decimal :cost, null: false
      t.integer :min_age, null: false
      t.integer :max_age, null: false
      t.decimal :min_weight, precision: 5, scale: 2
      t.decimal :max_weight, precision: 5, scale: 2
      t.string :belt, null: false
      t.string :sex, null: false

      t.timestamps
    end
  end
end