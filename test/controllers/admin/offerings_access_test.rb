require "test_helper"

class Admin::OfferingsAccessTest < ActionDispatch::IntegrationTest
  setup do
    now = Time.current
    Investment.insert_all([{
      user_id: @investor.id,
      offering_id: @offering.id,
      percent_of_class_by_total_raised: 100,
      bitcoin_address: "bc1qtestaddress000000000000000000000000000",
      created_at: now,
      updated_at: now
    }])
  end

  test "partner can list offerings and view offering show page" do
    sign_in @partner

    get admin_offerings_path
    assert_response :success
    assert_match @offering.name, response.body
    assert_no_match "New Offering", response.body
    assert_no_match "Edit Offering", response.body

    get admin_offering_path(@offering)
    assert_response :success
    assert_match @offering.name, response.body
    assert_match @investor.full_name, response.body
    assert_no_match "Edit Offering", response.body
  end

  test "partner can preview and export addresses" do
    sign_in @partner

    post preview_export_addresses_admin_offering_path(@offering), params: { btc_amount: "1.0" }
    assert_response :success
    assert_match "Export preview", response.body
    assert_match @investor.full_name, response.body

    post export_addresses_admin_offering_path(@offering), params: { btc_amount: "1.0" }
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match @investor.full_name, response.body
  end

  test "partner cannot edit or create offerings" do
    sign_in @partner

    get new_admin_offering_path
    assert_redirected_to admin_offerings_path

    get edit_admin_offering_path(@offering)
    assert_redirected_to admin_offerings_path

    patch admin_offering_path(@offering), params: { offering: { name: "Changed Name" } }
    assert_redirected_to admin_offerings_path
    assert_equal "Test Offering", @offering.reload.name
  end

  test "investor cannot access offerings" do
    sign_in @investor

    get admin_offerings_path
    assert_redirected_to root_path

    get admin_offering_path(@offering)
    assert_redirected_to root_path

    post preview_export_addresses_admin_offering_path(@offering), params: { btc_amount: "1.0" }
    assert_redirected_to root_path
  end

  test "partner nav includes Offerings link" do
    sign_in @partner

    get investments_path
    assert_response :success
    assert_match(/Offerings/, response.body)
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
