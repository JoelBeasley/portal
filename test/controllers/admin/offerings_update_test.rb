require "test_helper"

class Admin::OfferingsUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = User.create!(
      first_name: "Sam",
      last_name: "Super",
      email: "super-admin-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :super_admin
    )
  end

  test "updating offering carried interest and btc address succeeds and creates audit" do
    sign_in @super_admin

    patch admin_offering_path(@offering), params: {
      offering: {
        name: @offering.name,
        carried_interest: "8.84",
        carried_interest_bitcoin_address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
      }
    }

    assert_redirected_to admin_offering_path(@offering)
    @offering.reload
    assert_equal BigDecimal("8.84"), @offering.carried_interest
    assert_equal "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", @offering.carried_interest_bitcoin_address

    audit = Audited::Audit.where(auditable: @offering, action: "update").last
    assert audit.present?
    assert audit.audited_changes.key?("carried_interest")
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password"
      }
    }
  end
end
