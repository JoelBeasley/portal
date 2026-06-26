require "test_helper"

class Admin::SitesUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = User.create!(
      first_name: "Sam",
      last_name: "Super",
      email: "super-admin-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :super_admin
    )
    sign_in @super_admin
  end

  test "super admin can update default machine counts" do
    @site.update!(default_current_machines: 80, default_projected_machines: 325)

    patch admin_site_path(@site), params: {
      site: site_attributes(
        default_current_machines: 42,
        default_projected_machines: 150
      )
    }

    assert_redirected_to admin_site_path(@site)
    @site.reload
    assert_equal 42, @site.default_current_machines
    assert_equal 150, @site.default_projected_machines
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

  def site_attributes(overrides = {})
    {
      name: @site.name,
      slug: @site.slug,
      description: @site.description,
      location: @site.location,
      power_source: @site.power_source,
      model: @site.model,
      size_mw: @site.size_mw,
      status: @site.status,
      power_cost: @site.power_cost,
      offering_id: @site.offering_id,
      default_current_machines: @site.default_current_machines,
      default_projected_machines: @site.default_projected_machines
    }.merge(overrides)
  end
end
