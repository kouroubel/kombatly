class CreateTeamAdminRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :team_admin_roles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :team, null: false, foreign_key: true, index: { unique: true }
      
      t.timestamps
    end
  end
end