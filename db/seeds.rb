# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

super_admin = User.find_or_initialize_by(email: "joel@sovrn.com")
super_admin.role = :super_admin
super_admin.password = "password"
super_admin.password_confirmation = "password"
super_admin.save!

regular_admin = User.find_or_initialize_by(email: "admin@sovrn.com")
regular_admin.role = :admin
regular_admin.password = "password"
regular_admin.password_confirmation = "password"
regular_admin.save!

investor = User.find_or_initialize_by(email: "investor@sovrn.com")
investor.role = :investor
investor.password = "password"
investor.password_confirmation = "password"
investor.save!

digital_midstream = Project.find_or_create_by!(name: "Digital Midstream Genisis")
["Hash Dock", "Hailey's Mill", "Bluegrass"].each do |site_name|
  Site.find_or_create_by!(name: site_name, project: digital_midstream)
end
digital_investment = super_admin.investments.find_or_initialize_by(project: digital_midstream)
digital_investment.project = digital_midstream
digital_investment.save!

moon_lander = Project.find_or_create_by!(name: "Moon Lander")
["Dark side", "Light side"].each do |site_name|
  Site.find_or_create_by!(name: site_name, project: moon_lander)
end
moon_investment = regular_admin.investments.find_or_initialize_by(project: moon_lander)
moon_investment.project = moon_lander
moon_investment.save!

investor_investment = investor.investments.find_or_initialize_by(project: digital_midstream)
investor_investment.project = digital_midstream
investor_investment.save!
