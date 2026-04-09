class Admin::SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @sites = Site.all.order(name: :asc)
  end

  def new
    @site = Site.new
  end

  def create
    @site = Site.new(site_params)

    if @site.save
      redirect_to admin_sites_path, notice: "Site created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.admin?
  end

  def site_params
    params.require(:site).permit(:name, :slug, :description)
  end
end