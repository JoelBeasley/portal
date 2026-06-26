require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "partner can access sites and call list but not admin area" do
    partner = User.new(role: :partner)

    assert partner.can_access_sites?
    assert partner.can_access_call_list?
    assert_not partner.can_access_admin_area?
    assert_not partner.can_manage_sites?
  end

  test "investor cannot access sites" do
    investor = User.new(role: :investor)

    assert_not investor.can_access_sites?
    assert_not investor.can_access_call_list?
  end

  test "admin can access sites" do
    admin = User.new(role: :admin)

    assert admin.can_access_sites?
    assert admin.can_access_admin_area?
    assert_not admin.can_manage_sites?
  end
end
