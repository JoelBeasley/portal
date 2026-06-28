require "test_helper"

class Admin::FindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @finder = @offering.finders.create!(
      name: "Original Finder",
      btc_address: "bc1qtestaddress000000000000000000000000000",
      fee_percent: 50
    )
  end

  test "admin can create finder" do
    sign_in @admin

    assert_difference "@offering.finders.count", 1 do
      post admin_offering_finders_path(@offering), params: {
        finder: {
          name: "New Finder",
          btc_address: "bc1qtestaddress000000000000000000000000000",
          fee_percent: 25
        }
      }
    end

    assert_redirected_to admin_offering_path(@offering, manage_finders: true)
    assert_match "Finder added successfully.", flash[:notice]
  end

  test "admin can update finder" do
    sign_in @admin

    patch admin_offering_finder_path(@offering, @finder), params: {
      finder: {
        name: "Updated Finder",
        fee_percent: 75
      }
    }

    assert_redirected_to admin_offering_path(@offering, manage_finders: true)
    assert_equal "Updated Finder", @finder.reload.name
    assert_equal 75, @finder.fee_percent.to_i
  end

  test "admin can destroy finder" do
    sign_in @admin

    assert_difference "@offering.finders.count", -1 do
      delete admin_offering_finder_path(@offering, @finder)
    end

    assert_redirected_to admin_offering_path(@offering, manage_finders: true)
    assert_match "Finder removed successfully.", flash[:notice]
  end

  test "create with invalid data redirects with alert" do
    sign_in @admin

    post admin_offering_finders_path(@offering), params: {
      finder: { name: "", fee_percent: 50 }
    }

    assert_redirected_to admin_offering_path(@offering, manage_finders: true)
    assert_match "Name can't be blank", flash[:alert]
  end

  test "investor cannot manage finders" do
    sign_in @investor

    post admin_offering_finders_path(@offering), params: {
      finder: { name: "Blocked", fee_percent: 10 }
    }
    assert_redirected_to root_path

    patch admin_offering_finder_path(@offering, @finder), params: {
      finder: { name: "Blocked" }
    }
    assert_redirected_to root_path

    delete admin_offering_finder_path(@offering, @finder)
    assert_redirected_to root_path
    assert Finder.exists?(@finder.id)
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
