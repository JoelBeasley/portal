class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def show; end

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

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end
end
