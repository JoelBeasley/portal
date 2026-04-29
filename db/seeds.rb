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

digital_midstream = Offering.find_or_create_by!(name: "Digital Midstream Genesis, LLC")

# Site size is stored in MW; n/a leaves size_mw blank.
[
  {
    name: "Liberty Point",
    location: "TN",
    power_source: "Natural Gas / Ethane",
    model: "BTC Mining / CO2",
    size_mw: 8.35,
    status: :paused,
    power_cost: -0.04
  },
  {
    name: "Hailey's Mill",
    location: "KY",
    power_source: "Natural Gas",
    model: "BTC Mining",
    size_mw: 1.5,
    status: :construction,
    power_cost: 0.02
  },
  {
    name: "Bluegrass",
    location: "KY",
    power_source: "Natural Gas",
    model: "BTC Mining",
    size_mw: 1.5,
    status: :development,
    power_cost: 0.01
  },
  {
    name: "Hash Dock",
    location: "KY",
    power_source: "Grid",
    model: "BTC Mining",
    size_mw: nil,
    status: :operating,
    power_cost: 0.08
  }
].each do |attrs|
  site = Site.find_or_initialize_by(name: attrs.fetch(:name), offering: digital_midstream)
  site.assign_attributes(attrs.except(:name))
  site.save!
end

digital_investment = super_admin.investments.find_or_initialize_by(offering: digital_midstream)
digital_investment.assign_attributes(
  offering: digital_midstream,
  invested_amount: 125_000,
  investor_since: Date.new(2025, 11, 1),
  company_or_nickname: nil
)
digital_investment.save!

moon_lander = Offering.find_or_create_by!(name: "Moon Lander")
["Dark side", "Light side"].each do |site_name|
  Site.find_or_create_by!(name: site_name, offering: moon_lander)
end

moon_investment = regular_admin.investments.find_or_initialize_by(offering: moon_lander)
moon_investment.assign_attributes(
  offering: moon_lander,
  invested_amount: 50_000,
  investor_since: Date.new(2026, 1, 15),
  company_or_nickname: "Lunar Ops LLC"
)
moon_investment.save!

investor_investment = investor.investments.find_or_initialize_by(offering: digital_midstream)
investor_investment.assign_attributes(
  offering: digital_midstream,
  invested_amount: 75_000,
  investor_since: Date.new(2026, 2, 1),
  company_or_nickname: "Atlas Mining Co."
)
investor_investment.save!

User.investor.find_each { |user| InvestorProfile.prefill_from_user!(user) }

Investment.find_each do |investment|
  next unless (pid = investment.user&.investor_profile&.id)

  investment.update_column(:investor_profile_id, pid) if investment.investor_profile_id != pid
end
