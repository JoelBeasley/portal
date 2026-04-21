class InvestorProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_investor!
  before_action :set_investor_profile, only: [:show, :edit, :update]

  def index
    @investor_profile = current_user.investor_profile
    @investments = current_user.investments.includes(:offering).order(created_at: :desc)
  end

  def create
    if current_user.investor_profile.present?
      redirect_to investor_profiles_path, notice: "You already have an investor profile."
      return
    end

    InvestorProfile.prefill_from_user!(current_user)
    redirect_to edit_investor_profile_path(current_user.investor_profile),
                notice: "Your investor profile has been created. Review and save any changes."
  end

  def show
  end

  def edit
  end

  def update
    if @investor_profile.update(investor_profile_params)
      redirect_to investor_profile_path(@investor_profile), notice: "Your investor profile was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_investor!
    return if current_user.investor?

    redirect_to root_path, alert: "Access denied."
  end

  def set_investor_profile
    profile = current_user.investor_profile
    unless profile && profile.id == params[:id].to_i
      redirect_to investor_profiles_path, alert: "That investor profile was not found."
      return
    end

    @investor_profile = profile
  end

  def investor_profile_params
    params.require(:investor_profile).permit(*InvestorProfile::PERMITTED_ATTRIBUTES)
  end
end
