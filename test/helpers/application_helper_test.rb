require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper
  include Devise::Test::ControllerHelpers

  test "show_sites_nav_link for partner" do
    @user = User.new(role: :partner)
    def current_user
      @user
    end

    assert show_sites_nav_link?
    assert show_call_list_nav_link?
    assert_includes sites_nav_link_classes, "text-slate-200"
  end

  test "show_sites_nav_link for admin" do
    @user = User.new(role: :admin)
    def current_user
      @user
    end

    assert show_sites_nav_link?
    assert_includes sites_nav_link_classes, "text-blue-300"
  end

  test "show_sites_nav_link for investor" do
    @user = User.new(role: :investor)
    def current_user
      @user
    end

    assert_not show_sites_nav_link?
  end
end
