class Admin::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @projects = Project.includes(:sites, investments: :user).order(:name)
  end

  def show
    @project = Project.find(params[:id])
    @sites = @project.sites.order(:name)
    @investments = @project.investments.includes(:user).order(created_at: :desc)
    @investors = @project.users.order(:email)
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end
end
