class Admin::SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :require_super_admin, only: [:new, :create]

  def index
    @sites = Site.all.order(name: :asc)
  end

  def new
    @site = Site.new
    @offerings = Offering.order(:name)
  end

  def create
    @site = Site.new(site_params)
    @offerings = Offering.order(:name)

    if @site.save
      redirect_to admin_sites_path, notice: "Site created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def require_super_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_manage_sites?
  end

  def site_params
    params.require(:site).permit(:name, :slug, :description, :offering_id)
  end
end