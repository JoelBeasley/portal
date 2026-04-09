# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

["Hash Dock", "Hailey's Mill", "Bluegrass"].each do |site_name|
  Site.find_or_create_by!(name: site_name)
end

admin = User.find_or_initialize_by(email: "joel@sovrn.com")
admin.role = :admin
admin.password = "password"
admin.password_confirmation = "password"
admin.save!

dmg = admin.investments.find_or_initialize_by(name: "DMG")
dmg.save!
dmg.sites = Site.where(name: ["Bluegrass"])

exotic_ridge = admin.investments.find_or_initialize_by(name: "ExoticRidge")
exotic_ridge.save!
exotic_ridge.sites = Site.where(name: ["Hailey's Mill", "Hash Dock"])
