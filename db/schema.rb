# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_17_103300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "athletes", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.string "fullname", null: false
    t.date "birthdate", null: false
    t.decimal "weight", precision: 4, scale: 1
    t.string "belt", null: false
    t.string "sex", null: false
    t.string "card_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_athletes_on_team_id"
  end

  create_table "bouts", force: :cascade do |t|
    t.bigint "division_id", null: false
    t.bigint "athlete_a_id"
    t.bigint "athlete_b_id"
    t.bigint "winner_id"
    t.integer "round"
    t.datetime "scheduled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["athlete_a_id"], name: "index_bouts_on_athlete_a_id"
    t.index ["athlete_b_id"], name: "index_bouts_on_athlete_b_id"
    t.index ["division_id"], name: "index_bouts_on_division_id"
    t.index ["winner_id"], name: "index_bouts_on_winner_id"
  end

  create_table "divisions", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "event_id", null: false
    t.decimal "cost", null: false
    t.integer "min_age", null: false
    t.integer "max_age", null: false
    t.decimal "min_weight", precision: 5, scale: 2
    t.decimal "max_weight", precision: 5, scale: 2
    t.string "belt", null: false
    t.string "sex", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_divisions_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "location"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "point_events", force: :cascade do |t|
    t.bigint "bout_id", null: false
    t.bigint "athlete_id", null: false
    t.string "technique"
    t.integer "points"
    t.datetime "scored_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["athlete_id"], name: "index_point_events_on_athlete_id"
    t.index ["bout_id"], name: "index_point_events_on_bout_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "athlete_id", null: false
    t.bigint "division_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["athlete_id"], name: "index_registrations_on_athlete_id"
    t.index ["division_id"], name: "index_registrations_on_division_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "team_admin_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_admin_id"], name: "index_teams_on_team_admin_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "fullname"
    t.integer "role", default: 0, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "athletes", "teams"
  add_foreign_key "bouts", "athletes", column: "athlete_a_id"
  add_foreign_key "bouts", "athletes", column: "athlete_b_id"
  add_foreign_key "bouts", "athletes", column: "winner_id"
  add_foreign_key "bouts", "divisions"
  add_foreign_key "divisions", "events"
  add_foreign_key "point_events", "athletes"
  add_foreign_key "point_events", "bouts"
  add_foreign_key "registrations", "athletes"
  add_foreign_key "registrations", "divisions"
  add_foreign_key "teams", "users", column: "team_admin_id"
  add_foreign_key "users", "teams"
end
