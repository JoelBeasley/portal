class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def show
    @investors_needing_btc_count = User.investors_needing_bitcoin_address.count
  end

  def send_welcome_emails
    investors = User.investor.where(welcome_password_set_at: nil).order(:email)

    if investors.none?
      redirect_to admin_dashboard_path, notice: "No pending investors found. Everyone has already set a password."
      return
    end

    result = Admin::InvestorWelcomeEmailSender.call(investors)
    flash_type, message = Admin::InvestorWelcomeEmailSender.flash_for(result)
    redirect_to admin_dashboard_path, flash_type => message
  end

  def send_btc_reminder_emails
    investors = User.investors_needing_bitcoin_address.order(:email)

    if investors.none?
      redirect_to admin_dashboard_path, notice: "No investors found who have set a password and are missing a Bitcoin payout address."
      return
    end

    result = Admin::InvestorBtcReminderEmailSender.call(investors)
    flash_type, message = Admin::InvestorBtcReminderEmailSender.flash_for(result)
    redirect_to admin_dashboard_path, flash_type => message
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end
end
