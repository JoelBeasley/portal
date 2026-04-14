class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def show; end

  def send_welcome_emails
    investors = User.investor.where(welcome_password_set_at: nil).order(:email)
    sent_count = 0

    investors.find_each do |investor|
      token = investor.send(:set_reset_password_token)
      Admin::InvestorWelcomeMailer.with(user: investor, token: token).welcome_email.deliver_now
      sent_count += 1
    end

    if sent_count.zero?
      redirect_to admin_dashboard_path, notice: "No pending investors found. Everyone has already set a password."
    else
      redirect_to admin_dashboard_path, notice: "Sent welcome emails to #{sent_count} investor#{'s' unless sent_count == 1} who still need to set a password."
    end
  rescue StandardError => e
    Rails.logger.error("Failed sending welcome emails: #{e.class} - #{e.message}")
    redirect_to admin_dashboard_path, alert: "Could not send welcome emails. Please check mail delivery logs."
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end
end
