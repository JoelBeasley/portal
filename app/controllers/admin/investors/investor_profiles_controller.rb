class Admin::Investors::InvestorProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_user_directory_access
  before_action :set_investor

  def edit
    @investor_profile = @investor.investor_profile || @investor.create_investor_profile!
  end

  def update
    @investor_profile = @investor.investor_profile || @investor.create_investor_profile!
    if @investor_profile.update(investor_profile_params)
      redirect_to admin_investor_path(@investor), notice: "Investor profile was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_investor
    @investor = User.investor.find(params[:investor_id])
  end

  def require_user_directory_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_manage_user_directory?
  end

  def investor_profile_params
    params.require(:investor_profile).permit(*InvestorProfile::PERMITTED_ATTRIBUTES)
  end
end
