require "test_helper"

class Admin::SitesAccessTest < ActionDispatch::IntegrationTest
  test "partner can list sites and open pool analytics" do
    sign_in @partner

    get admin_sites_path
    assert_response :success
    assert_match "Test Site", response.body
    assert_match "Pool analytics", response.body
    assert_no_match "Site details", response.body

    get admin_site_pool_dashboard_path(@site)
    assert_response :success
    assert_match "Pool analytics", response.body
    assert_no_match @site.braiins_pool_auth_token.to_s, response.body if @site.braiins_pool_auth_token.present?
  end

  test "partner cannot manage sites" do
    sign_in @partner

    get new_admin_site_path
    assert_redirected_to root_path

    get edit_admin_site_path(@site)
    assert_redirected_to root_path
  end

  test "investor cannot access sites" do
    sign_in @investor

    get admin_sites_path
    assert_redirected_to root_path

    get admin_site_pool_dashboard_path(@site)
    assert_redirected_to root_path
  end

  test "admin can access sites index" do
    sign_in @admin

    get admin_sites_path
    assert_response :success
    assert_match "Site details", response.body
  end

  test "partner can load btc price endpoint" do
    sign_in @partner

    get admin_site_analytics_btc_price_path, as: :json
    assert_includes [200, 502], response.status
  end

  test "partner nav includes Sites link on investments page" do
    sign_in @partner

    get investments_path
    assert_response :success
    assert_match(/Sites/, response.body)
    assert_match(/Call List/, response.body)
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
