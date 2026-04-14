class Admin::SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :require_super_admin, only: [:new, :create, :edit, :update]
  before_action :set_site, only: [:show, :edit, :update]

  def index
    @sites = Site.includes(:offering).order(name: :asc)
  end

  def show
  end

  def new
    @site = Site.new
    @offerings = Offering.order(:name)
  end

  def create
    permitted = site_params
    permitted = permitted.except(:braiins_pool_auth_token) if permitted[:braiins_pool_auth_token].blank?
    @site = Site.new(permitted)
    @offerings = Offering.order(:name)

    if @site.save
      redirect_to admin_sites_path, notice: "Site created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @offerings = Offering.order(:name)
  end

  def update
    @offerings = Offering.order(:name)
    permitted = site_params
    permitted = permitted.except(:braiins_pool_auth_token) if permitted[:braiins_pool_auth_token].blank?

    if @site.update(permitted)
      redirect_to admin_site_path(@site), notice: "Site updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_site
    @site = Site.find(params[:id])
  end

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def require_super_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_manage_sites?
  end

  def site_params
    params.require(:site).permit(:name, :slug, :description, :offering_id, :braiins_pool_auth_token)
  end
end