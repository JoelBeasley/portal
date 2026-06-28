require "test_helper"

class Admin::OfferingsFinderExportTest < ActionDispatch::IntegrationTest
  setup do
    @offering.finders.create!(
      name: "Fee Finder",
      btc_address: "bc1qtestaddress000000000000000000000000000",
      fee_percent: 100
    )
  end

  test "preview export renders show page with preview table" do
    price = BtcUsdPrice::Result.new(usd: 97_234.56, source: "CoinGecko", fetched_at: Time.current.utc.iso8601)
    sign_in @admin

    original_current = BtcUsdPrice.method(:current)
    BtcUsdPrice.define_singleton_method(:current) { price }
    begin
      post preview_export_finder_fees_admin_offering_path(@offering), params: { btc_amount: "1.0" }

      assert_response :success
      assert_match "Finders fee export preview", response.body
      assert_match "Fee Finder", response.body
      assert_match "1.00000000", response.body
      assert_match "USD amount", response.body
      assert_match "$97,234.56", response.body
    ensure
      BtcUsdPrice.define_singleton_method(:current, original_current)
    end
  end

  test "preview export renders error in modal when btc missing" do
    sign_in @admin

    post preview_export_finder_fees_admin_offering_path(@offering), params: { btc_amount: "" }

    assert_response :unprocessable_entity
    assert_match "Total BTC amount is required.", response.body
  end

  test "export returns csv" do
    sign_in @admin

    post export_finder_fees_admin_offering_path(@offering), params: { btc_amount: "1.0" }

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "Fee Finder", response.body
    assert_match "1.00000000", response.body
    assert_no_match "USD amount", response.body
  end

  test "offering show includes side by side exports and manage finders modal" do
    sign_in @admin

    get admin_offering_path(@offering)

    assert_response :success
    assert_match "Investor export", response.body
    assert_match "Finders fee export", response.body
    assert_match "Manage finders", response.body
    assert_match 'data-controller="modal offering-export-sync"', response.body
    assert_match "Add finder", response.body
    assert_match preview_export_finder_fees_admin_offering_path(@offering), response.body
    assert_match export_finder_fees_admin_offering_path(@offering), response.body
    assert_match "grid-cols-1 lg:grid-cols-2", response.body
  end

  test "offering show opens finders modal when manage_finders param is set" do
    sign_in @admin

    get admin_offering_path(@offering, manage_finders: true)

    assert_response :success
    assert_match 'data-modal-open-value="true"', response.body
    assert_no_match 'data-modal-target="modal" class="fixed inset-0 z-50 hidden"', response.body
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
