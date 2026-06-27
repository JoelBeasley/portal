require "test_helper"

class CallListControllerTest < ActionDispatch::IntegrationTest
  setup do
    @archived_investor = User.create!(
      first_name: "Arch",
      last_name: "Ived",
      email: "archived-call-list-controller-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :investor
    )
    @active_investor = User.create!(
      first_name: "Act",
      last_name: "Ive",
      email: "active-call-list-controller-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :investor
    )
    @active_investor.update_columns(welcome_password_set_at: Time.utc(2026, 6, 1, 12, 0, 0))

    now = Time.utc(2026, 6, 1, 12, 0, 0)
    Investment.insert_all([
      {
        user_id: @archived_investor.id,
        offering_id: @offering.id,
        archived_at: now,
        bitcoin_address: "bc1qarchived000000000000000000000000000",
        created_at: now,
        updated_at: now
      },
      {
        user_id: @active_investor.id,
        offering_id: @offering.id,
        archived_at: nil,
        bitcoin_address: "bc1qactive000000000000000000000000000",
        created_at: now,
        updated_at: now
      }
    ])
  end

  test "call list excludes investors with only archived investments" do
    sign_in @partner

    get call_list_path

    assert_response :success
    assert_match @active_investor.full_name, response.body
    assert_no_match @archived_investor.full_name, response.body
    assert_no_match "bc1qarchived000000000000000000000000000", response.body
    assert_match "bc1qactive000000000000000000000000000", response.body
  end

  test "investor cannot access call list" do
    sign_in @investor

    get call_list_path

    assert_redirected_to root_path
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
