# db/seeds.rb
require "faker"

puts "Clearing existing data..."
Registration.destroy_all
Bout.destroy_all
Division.destroy_all
Event.destroy_all
Athlete.destroy_all
TeamAdminRole.destroy_all
Team.destroy_all
User.destroy_all

puts "Seeding users..."

# ------------------------------------------------------------------------------------
# SUPERADMIN
# ------------------------------------------------------------------------------------
superadmin = User.create!(
  fullname: "Albert Roussos",
  email: "albert.roussos@gmail.com",
  password: "password",
  password_confirmation: "password",
  role: :superadmin,
  confirmed_at: Time.current
)
puts "Created Superadmin: #{superadmin.email}"

# ------------------------------------------------------------------------------------
# ORGANIZER
# ------------------------------------------------------------------------------------
organizer = User.create!(
  fullname: Faker::Name.name,
  email: "organizer@example.com",
  password: "password",
  password_confirmation: "password",
  role: :pending,
  confirmed_at: Time.current
)
puts "Created Organizer: #{organizer.email}"

# ------------------------------------------------------------------------------------
# TEAM ADMINS (1 per team)
# ------------------------------------------------------------------------------------
puts "Creating 5 team admins..."
team_admins = 5.times.map do |i|
  User.create!(
    fullname: Faker::Name.name,
    email: "teamadmin#{i+1}@example.com",
    password: "password",
    password_confirmation: "password",
    role: :team_admin,
    confirmed_at: Time.current
  )
end
puts "Created #{team_admins.count} team admins."

# ------------------------------------------------------------------------------------
# TEAMS (each with one unique team admin)
# ------------------------------------------------------------------------------------
team_names = [
  "Athens Tigers",
  "Sparta Warriors",
  "Thessaloniki Dragons",
  "Crete Panthers",
  "Patras Eagles"
]

teams = []

puts "Creating 5 teams..."
team_names.each_with_index do |name, i|
  team = Team.create!(name: name)
  TeamAdminRole.create!(user: team_admins[i], team: team)
  teams << team
  puts "Created team #{team.name} with admin #{team_admins[i].email}"
end

# ------------------------------------------------------------------------------------
# EVENT
# ------------------------------------------------------------------------------------
event = Event.create!(
  name: "Kids National Cup 2025",
  location: "Athens Olympic Arena",
  start_date: Date.today + 30.days,
  end_date: Date.today + 30.days,
  description: "Youth championship for ages 6–7.",
  organizer: organizer
)

puts "Created event: #{event.name}"

# ------------------------------------------------------------------------------------
# DIVISIONS (8 total = 2 sexes × 2 birth-year groups × 4 weight classes)
# ------------------------------------------------------------------------------------

puts "Creating divisions..."

divisions_data = []
sexes = ["Male", "Female"]
years = [2019, 2020]

# Correct weight boundaries:
# -25kg: 0–25.0
# -30kg: 25.1–30.0
# -35kg: 30.1–35.0
# +35kg: 35.1–200.0
weights = [
  { name: "-25kg", min: 0, max: 25.0 },
  { name: "-30kg", min: 25.1, max: 30.0 },
  { name: "-35kg", min: 30.1, max: 35.0 },
  { name: "+35kg", min: 35.1, max: 200.0 }
]

years.each do |year|
  sexes.each do |sex|
    weights.each do |w|
      divisions_data << {
        name: "#{sex} #{year} #{w[:name]}",
        min_age: 6,
        max_age: 7,
        min_weight: w[:min],
        max_weight: w[:max],
        belt: "White",
        cost: 25,
        sex: sex,
        event: event
      }
    end
  end
end

divisions = divisions_data.map { |data| Division.create!(data) }

puts "Created #{divisions.count} divisions."

# ------------------------------------------------------------------------------------
# ATHLETES (15–20 per team)
# Weight range guaranteed: 25–38 kg
# ------------------------------------------------------------------------------------

puts "Creating athletes..."

athletes = []

teams.each do |team|
  num = rand(15..20)

  num.times do
    sex = ["Male", "Female"].sample

    birth_year = [2019, 2020].sample
    birthdate = Date.new(birth_year, rand(1..12), rand(1..28))

    # Strictly enforce 25.0–38.0
    # And assign correctly into weight-group buckets
    weight =
      case rand(1..4)
      when 1 then 25.0                       # exact boundary to fit -25kg
      when 2 then rand(25.1..30.0)           # -30kg
      when 3 then rand(30.1..35.0)           # -35kg
      else rand(35.1..38.0)                  # +35kg (capped at 38)
      end

    athlete = Athlete.create!(
      fullname: Faker::Name.name,
      birthdate: birthdate,
      weight: weight.round(1),
      belt: "White",
      sex: sex,
      team: team
    )

    athletes << athlete
  end

  puts "Created #{num} athletes for #{team.name}"
end

puts "Total athletes created: #{athletes.count}"

# ------------------------------------------------------------------------------------
# NO REGISTRATIONS
# ------------------------------------------------------------------------------------
puts "Skipping registrations (0 created)."

puts "\n" + "="*80
puts "SEEDING COMPLETE!"
puts "="*80

puts "\nLogin Credentials:"
puts "Superadmin: #{superadmin.email} / password"
puts "Organizer:  #{organizer.email} / password"
team_admins.each { |ta| puts "Team Admin: #{ta.email} / password" }

puts "="*80
puts "Stats:"
puts "Users: #{User.count}"
puts "Teams: #{Team.count}"
puts "Events: #{Event.count}"
puts "Divisions: #{Division.count}"
puts "Athletes: #{Athlete.count}"
puts "Registrations: #{Registration.count}"
puts "="*80
