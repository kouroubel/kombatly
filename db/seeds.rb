# db/seeds.rb
require "faker"

puts "Clearing existing data..."
Registration.destroy_all rescue nil
PointEvent.destroy_all rescue nil
Bout.destroy_all rescue nil
Division.destroy_all
Event.destroy_all
Athlete.destroy_all
Team.destroy_all
User.destroy_all

puts "Seeding users..."
# Admin
admin = User.create!(
  fullname: "Albert Roussos",
  email: "albert.roussos@gmail.com",
  password: "password",
  password_confirmation: "password",
  role: :admin,
  confirmed_at: Time.current
)

# Team admins
team_admins = 3.times.map do |i|
  User.create!(
    fullname: "TeamAdmin #{i + 1}",
    email: "teamadmin#{i + 1}@example.com",
    password: "password",
    password_confirmation: "password",
    role: :team,
    confirmed_at: Time.current
  )
end

puts "Seeding teams..."
team_names = ["Red Dragons", "Blue Tigers", "Golden Eagles"]
teams = team_names.each_with_index.map do |name, i|
  Team.create!(
    name: name,
    team_admin: team_admins[i]
  )
end

# Link team_admin back to their team
teams.each_with_index do |team, i|
  u = team_admins[i]
  u.update!(team: team)
end

puts "Seeding Event and Divisions..."
event = Event.create!(
  name: "Annual Karate Championship",
  location: "Athens Arena",
  start_date: Date.today + 30.days
)

divisions_data = [
  { name: "White Belt Boys U12", min_age: 8, max_age: 12, min_weight: 0, max_weight: 40, belt: "White", sex: "Male", cost: 25 },
  { name: "White Belt Girls U12", min_age: 8, max_age: 12, min_weight: 0, max_weight: 40, belt: "White", sex: "Female", cost: 25 },
  { name: "Yellow/Green Belt Boys U16", min_age: 13, max_age: 16, min_weight: 0, max_weight: 60, belt: "Yellow", sex: "Male", cost: 30 },
  { name: "Yellow/Green Belt Girls U16", min_age: 13, max_age: 16, min_weight: 0, max_weight: 60, belt: "Yellow", sex: "Female", cost: 30 },
  { name: "Blue/Red/Black Adults Male", min_age: 17, max_age: 40, min_weight: 0, max_weight: 100, belt: "Blue", sex: "Male", cost: 30 },
  { name: "Blue/Red/Black Adults Female", min_age: 17, max_age: 40, min_weight: 0, max_weight: 100, belt: "Blue", sex: "Female", cost: 30 }
]

divisions = divisions_data.map do |div|
  Division.create!(div.merge(event: event))
end

puts "Seeding athletes..."
belts = Athlete::BELTS
sexes = Athlete::SEXES

100.times do
  # Pick a division so athlete is eligible
  div = divisions.sample
  team = teams.sample

  Athlete.create!(
    fullname: "#{Faker::Name.first_name} #{Faker::Name.last_name}",
    birthdate: Faker::Date.birthday(min_age: div[:min_age], max_age: div[:max_age]),
    weight: rand(div[:min_weight]..div[:max_weight]).round(1), # 1 decimal
    belt: div[:belt] == "Any" ? belts.sample : div[:belt],
    sex: div[:sex] == "Any" ? sexes.sample : div[:sex],
    team: team
  )
end

puts "Seeding complete!"
