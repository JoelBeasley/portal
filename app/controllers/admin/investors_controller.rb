class Admin::InvestorsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_user_directory_access

  def index
    @investors = User.investor.order(:last_name, :first_name, :email)
  end

  def show
    @investor = User.investor.find(params[:id])
    @investor_profile = @investor.investor_profile || @investor.create_investor_profile!
    @investments = @investor.investments.includes(:offering).order(created_at: :desc)
  end

  private

  def require_user_directory_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_manage_user_directory?
  end
end
