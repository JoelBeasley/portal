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

  test "call_list_directory excludes users with only archived investments" do
    archived_investor = User.create!(
      first_name: "Arch",
      last_name: "Ived",
      email: "archived-call-list-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :investor
    )
    active_investor = User.create!(
      first_name: "Act",
      last_name: "Ive",
      email: "active-call-list-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :investor
    )
    offering = Offering.create!(name: "Call List Test Offering")
    now = Time.utc(2026, 6, 1, 12, 0, 0)

    Investment.insert_all([
      {
        user_id: archived_investor.id,
        offering_id: offering.id,
        archived_at: now,
        bitcoin_address: nil,
        created_at: now,
        updated_at: now
      },
      {
        user_id: active_investor.id,
        offering_id: offering.id,
        archived_at: nil,
        bitcoin_address: nil,
        created_at: now,
        updated_at: now
      }
    ])

    directory_ids = User.call_list_directory.pluck(:id)

    assert_includes directory_ids, active_investor.id
    assert_not_includes directory_ids, archived_investor.id
  end

  test "investors_needing_bitcoin_address excludes archived investments" do
    investor = User.create!(
      first_name: "Btc",
      last_name: "Reminder",
      email: "btc-reminder-test@example.com",
      password: "password",
      password_confirmation: "password",
      role: :investor
    )
    investor.update_columns(welcome_password_set_at: Time.utc(2026, 6, 1, 12, 0, 0))
    offering = Offering.create!(name: "BTC Reminder Test Offering")
    now = Time.utc(2026, 6, 1, 12, 0, 0)

    Investment.insert_all([{
      user_id: investor.id,
      offering_id: offering.id,
      archived_at: now,
      created_at: now,
      updated_at: now
    }])

    assert_not_includes User.investors_needing_bitcoin_address.pluck(:id), investor.id
  end

  test "investments_missing_bitcoin_address ignores archived investments" do
    offering = Offering.create!(name: "Missing BTC Test Offering")
    now = Time.utc(2026, 6, 1, 12, 0, 0)

    Investment.insert_all([
      {
        user_id: @investor.id,
        offering_id: offering.id,
        archived_at: now,
        bitcoin_address: nil,
        created_at: now,
        updated_at: now
      },
      {
        user_id: @investor.id,
        offering_id: @offering.id,
        archived_at: nil,
        bitcoin_address: "bc1qtestaddress000000000000000000000000000",
        created_at: now,
        updated_at: now
      }
    ])

    assert_empty @investor.investments_missing_bitcoin_address
    assert_equal :complete, @investor.bitcoin_address_status
  end
end
