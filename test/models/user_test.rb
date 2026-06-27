require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "partner can access sites and call list but not admin area" do
    partner = User.new(role: :partner)

    assert partner.can_access_sites?
    assert partner.can_access_offerings?
    assert partner.can_access_call_list?
    assert_not partner.can_access_admin_area?
    assert_not partner.can_manage_sites?
  end

  test "investor cannot access sites" do
    investor = User.new(role: :investor)

    assert_not investor.can_access_sites?
    assert_not investor.can_access_call_list?
  end

  test "investor_directory includes partners and admins with investments" do
    partner = User.create!(
      first_name: "Michael",
      last_name: "Wade",
      email: "michael-wade-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :partner
    )
    admin = User.create!(
      first_name: "Geoff",
      last_name: "Haynes",
      email: "geoff-haynes-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :admin
    )
    offering = Offering.create!(name: "Partner Test Offering")
    now = Time.current

    Investment.insert_all([
      { user_id: partner.id, offering_id: offering.id, created_at: now, updated_at: now },
      { user_id: admin.id, offering_id: offering.id, created_at: now, updated_at: now }
    ])

    directory_ids = User.investor_directory.pluck(:id)

    assert_includes directory_ids, partner.id
    assert_includes directory_ids, admin.id
    assert_includes directory_ids, @investor.id
    assert_not_includes directory_ids, @partner.id
  end

  test "admin can access sites" do
    admin = User.new(role: :admin)

    assert admin.can_access_sites?
    assert admin.can_access_admin_area?
    assert_not admin.can_manage_sites?
  end
end
