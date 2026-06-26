require "test_helper"

class Admin::InvestorsDirectoryTest < ActionDispatch::IntegrationTest
  setup do
    @partner_investor = User.create!(
      first_name: "Michael",
      last_name: "Wade",
      email: "michael-wade-directory-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :partner
    )
    now = Time.current
    Investment.insert_all([{
      user_id: @partner_investor.id,
      offering_id: @offering.id,
      created_at: now,
      updated_at: now
    }])
  end

  test "investors index includes partners with investments" do
    sign_in @admin

    get admin_investors_path

    assert_response :success
    assert_match @partner_investor.full_name, response.body
  end

  test "offering show includes partners with investments" do
    sign_in @admin

    get admin_offering_path(@offering)

    assert_response :success
    assert_match @partner_investor.full_name, response.body
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
