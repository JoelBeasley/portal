ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    setup do
      @offering = Offering.create!(name: "Test Offering")
      @site = Site.create!(name: "Test Site", offering: @offering)
      @partner = User.create!(
        first_name: "Pat",
        last_name: "Partner",
        email: "partner-test@example.com",
        password: "password",
        password_confirmation: "password",
        role: :partner
      )
      @investor = User.create!(
        first_name: "Ivy",
        last_name: "Investor",
        email: "investor-test@example.com",
        password: "password",
        password_confirmation: "password",
        role: :investor
      )
      @admin = User.create!(
        first_name: "Ada",
        last_name: "Admin",
        email: "admin-test@example.com",
        password: "password",
        password_confirmation: "password",
        role: :admin
      )
    end
  end
end
