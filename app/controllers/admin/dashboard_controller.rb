class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def show; end

  def send_welcome_emails
    investors = User.investor.order(:email)
    sent_count = 0

    investors.find_each do |investor|
      token = investor.send(:set_reset_password_token)
      Admin::InvestorWelcomeMailer.with(user: investor, token: token).welcome_email.deliver_later
      sent_count += 1
    end

    redirect_to admin_dashboard_path, notice: "Queued welcome emails for #{sent_count} investor#{'s' unless sent_count == 1}."
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end
end
