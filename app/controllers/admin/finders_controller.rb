class Admin::FindersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_offerings_access
  before_action :set_offering
  before_action :set_finder, only: [:update, :destroy]

  def create
    @finder = @offering.finders.build(finder_params)

    if @finder.save
      redirect_to admin_offering_path(@offering, manage_finders: true), notice: "Finder added successfully."
    else
      redirect_to admin_offering_path(@offering, manage_finders: true), alert: @finder.errors.full_messages.to_sentence
    end
  end

  def update
    if @finder.update(finder_params)
      redirect_to admin_offering_path(@offering, manage_finders: true), notice: "Finder updated successfully."
    else
      redirect_to admin_offering_path(@offering, manage_finders: true), alert: @finder.errors.full_messages.to_sentence
    end
  end

  def destroy
    @finder.destroy!
    redirect_to admin_offering_path(@offering, manage_finders: true), notice: "Finder removed successfully."
  end

  private

  def set_offering
    @offering = Offering.find(params[:offering_id])
  end

  def set_finder
    @finder = @offering.finders.find(params[:id])
  end

  def require_offerings_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_access_offerings?
  end

  def finder_params
    params.require(:finder).permit(:name, :btc_address, :fee_percent)
  end
end
