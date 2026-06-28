require "test_helper"

class Admin::OfferingsExportTest < ActionDispatch::IntegrationTest
  setup do
    now = Time.current
    Investment.insert_all([{
      user_id: @investor.id,
      offering_id: @offering.id,
      percent_of_class_by_total_raised: 100,
      created_at: now,
      updated_at: now
    }])
  end

  test "preview export renders show page with preview table" do
    sign_in @admin

    post preview_export_addresses_admin_offering_path(@offering), params: { btc_amount: "1.0" }

    assert_response :success
    assert_match "Export preview", response.body
    assert_match @investor.full_name, response.body
    assert_match "1.00000000", response.body
    assert_match 'id="export-preview-title">Export preview', response.body
    assert_includes response.body, 'class="fixed inset-0 z-50" data-action="click-&gt;export-preview#closeOnBackdrop"'
  end

  test "preview export renders error in modal when btc missing" do
    sign_in @admin

    post preview_export_addresses_admin_offering_path(@offering), params: { btc_amount: "" }

    assert_response :unprocessable_entity
    assert_match "Total BTC amount is required.", response.body
  end

  test "preview export prefills finder fee amount from carried interest" do
    @offering.update!(
      carried_interest: 20,
      carried_interest_bitcoin_address: "bc1qtestaddress000000000000000000000000000"
    )
    sign_in @admin

    post preview_export_addresses_admin_offering_path(@offering), params: { btc_amount: "10" }

    assert_response :success
    assert_match 'data-offering-export-sync-target="finderBtcInput"', response.body
    assert_match 'value="0.10000000"', response.body
  end

  test "offering show includes export sync controller" do
    sign_in @admin

    get admin_offering_path(@offering)

    assert_response :success
    assert_match 'data-controller="modal offering-export-sync"', response.body
    assert_match 'data-offering-export-sync-target="investorBtcInput"', response.body
  end

  test "offering show includes separate preview and export forms" do
    sign_in @admin

    get admin_offering_path(@offering)

    assert_response :success
    assert_match 'data-controller="export-preview"', response.body
    assert_match "Preview Export", response.body
    assert_match preview_export_addresses_admin_offering_path(@offering), response.body
    assert_match export_addresses_admin_offering_path(@offering), response.body
    assert_match 'class="fixed inset-0 z-50 hidden"', response.body
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
