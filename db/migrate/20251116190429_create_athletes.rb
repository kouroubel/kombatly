class CreateAthletes < ActiveRecord::Migration[7.1]
  def change
    create_table :athletes do |t|
      t.references :team, null: false, foreign_key: true
      t.string :fullname, null: false
      t.date :birthdate, null: false
      t.decimal :weight, precision: 4, scale: 1
      t.string :belt, null: false
      t.string :sex, null: false

      t.timestamps
    end
  end
end
