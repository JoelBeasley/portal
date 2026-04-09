# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be run at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

super_admin = User.find_or_initialize_by(email: "joel@sovrn.com")
super_admin.assign_attributes(
  first_name: "Joel",
  last_name: "Beasley",
  role: :super_admin,
  password: "password",
  password_confirmation: "password"
)
super_admin.save!

regular_admin = User.find_or_initialize_by(email: "admin@sovrn.com")
regular_admin.assign_attributes(
  first_name: "Morgan",
  last_name: "Chen",
  role: :admin,
  password: "password",
  password_confirmation: "password"
)
regular_admin.save!

investor = User.find_or_initialize_by(email: "investor@sovrn.com")
investor.assign_attributes(
  first_name: "Riley",
  last_name: "Thornton",
  role: :investor,
  password: "password",
  password_confirmation: "password"
)
investor.save!

digital_midstream = Project.find_or_create_by!(name: "Digital Midstream Genisis")
["Hash Dock", "Hailey's Mill", "Bluegrass"].each do |site_name|
  Site.find_or_create_by!(name: site_name, project: digital_midstream)
end

digital_investment = super_admin.investments.find_or_initialize_by(project: digital_midstream)
digital_investment.assign_attributes(
  project: digital_midstream,
  amount_usd: 125_000,
  investor_since: Date.new(2025, 11, 1),
  company_or_nickname: nil
)
digital_investment.save!

moon_lander = Project.find_or_create_by!(name: "Moon Lander")
["Dark side", "Light side"].each do |site_name|
  Site.find_or_create_by!(name: site_name, project: moon_lander)
end

moon_investment = regular_admin.investments.find_or_initialize_by(project: moon_lander)
moon_investment.assign_attributes(
  project: moon_lander,
  amount_usd: 50_000,
  investor_since: Date.new(2026, 1, 15),
  company_or_nickname: "Lunar Ops LLC"
)
moon_investment.save!

investor_investment = investor.investments.find_or_initialize_by(project: digital_midstream)
investor_investment.assign_attributes(
  project: digital_midstream,
  amount_usd: 75_000,
  investor_since: Date.new(2026, 2, 1),
  company_or_nickname: "Atlas Mining Co."
)
investor_investment.save!
