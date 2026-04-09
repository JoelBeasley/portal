class Admin::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :require_super_admin, only: [:new, :create]

  def index
    @projects = Project.includes(:sites, investments: :user).order(:name)
  end

  def show
    @project = Project.find(params[:id])
    @sites = @project.sites.order(:name)
    @investments = @project.investments.includes(:user).order(created_at: :desc)
    @investors = @project.users.order(:email)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to admin_project_path(@project), notice: "Project created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def require_super_admin
    redirect_to admin_projects_path, alert: "Access denied." unless current_user.can_manage_projects?
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
