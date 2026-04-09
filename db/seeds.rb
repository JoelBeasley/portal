# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

admin = User.find_or_initialize_by(email: "joel@sovrn.com")
admin.role = :admin
admin.password = "password"
admin.password_confirmation = "password"
admin.save!

dmg_project = Project.find_or_create_by!(name: "DMG Project")
Site.find_or_create_by!(name: "Bluegrass", project: dmg_project)
dmg = admin.investments.find_or_initialize_by(project: dmg_project)
dmg.project = dmg_project
dmg.save!

exotic_project = Project.find_or_create_by!(name: "ExoticRidge Project")
Site.find_or_create_by!(name: "Hailey's Mill", project: exotic_project)
Site.find_or_create_by!(name: "Hash Dock", project: exotic_project)
exotic_ridge = admin.investments.find_or_initialize_by(project: exotic_project)
exotic_ridge.project = exotic_project
exotic_ridge.save!
