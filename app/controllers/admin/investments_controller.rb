class Admin::InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def assign
    @investment = Investment.new
    @users = User.where(role: [:investor, :admin]).order(:email)  # Admins can also be investors
    @projects = Project.order(:name)
  end

  def create_assignment
    user = User.find(params[:user_id])
    project = Project.find_by(id: params[:project_id])

    unless project
      redirect_to assign_admin_investments_path, alert: "Please select a project."
      return
    end

    investment = Investment.new(
      user: user,
      project: project,
      bitcoin_address: params[:bitcoin_address]
    )

    if investment.save
      redirect_to admin_project_path(project),
                  notice: "Investment created for #{user.email} in project #{project.name}."
    else
      redirect_to assign_admin_investments_path, alert: investment.errors.full_messages.join(", ")
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.admin?
  end
end