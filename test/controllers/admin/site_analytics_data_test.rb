require "test_helper"

class Admin::SiteAnalyticsDataTest < ActionDispatch::IntegrationTest
  setup do
    @site.update!(braiins_pool_auth_token: "test-pool-token")
    Rails.cache.clear
    sign_in @partner
    @original_fetch = Admin::SiteAnalyticsController.instance_method(:fetch_braiins_json)
  end

  teardown do
    Admin::SiteAnalyticsController.define_method(:fetch_braiins_json, @original_fetch)
    Rails.cache.clear
  end

  test "data response includes profile and workers from Braiins proxy" do
    endpoints_called = []

    Admin::SiteAnalyticsController.define_method(:fetch_braiins_json) do |endpoint, token|
      endpoints_called << endpoint
      case endpoint
      when /profile/
        {
          "btc" => {
            "ok_workers" => 3,
            "low_workers" => 1,
            "off_workers" => 2,
            "dis_workers" => 0,
            "hash_rate_unit" => "Th/s",
            "hash_rate_5m" => 1500.5,
            "hash_rate_24h" => 1480.2
          }
        }
      when /workers/
        {
          "btc" => {
            "workers" => {
              "account.rig01" => {
                "state" => "ok",
                "hash_rate_unit" => "Th/s",
                "hash_rate_5m" => 100,
                "hash_rate_24h" => 99,
                "last_share" => 1_700_000_000
              }
            }
          }
        }
      when /hash_rate_daily/
        { "btc" => [] }
      when /rewards/
        { "btc" => { "daily_rewards" => [] } }
      else
        {}
      end
    end

    post admin_site_analytics_site_data_path(@site), params: {
      hashrate_endpoint: "https://pool.braiins.com/accounts/hash_rate_daily/json/btc",
      rewards_endpoint: "https://pool.braiins.com/accounts/rewards/json/btc"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert body.key?("profile")
    assert body.key?("workers")
    assert_equal 3, body.dig("profile", "btc", "ok_workers")
    assert body.dig("workers", "btc", "workers").key?("account.rig01")
    assert endpoints_called.any? { |url| url.include?("profile") }
    assert endpoints_called.any? { |url| url.include?("workers") }
    assert_equal 4, endpoints_called.length
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
