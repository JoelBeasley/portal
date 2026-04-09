class Admin::InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :require_super_admin, only: [:assign, :create_assignment]

  def assign
    @investment = Investment.new
    @users = User.where(role: [:investor, :admin, :super_admin]).order(:email)
    @projects = Project.order(:name)
  end

  def create_assignment
    user = User.find(params[:user_id])
    project = Project.find_by(id: params[:project_id])

    unless project
      redirect_to assign_admin_investments_path, alert: "Please select a project."
      return
    end

    raw_label = params[:investment_label].to_s.strip
    company_or_nickname =
      if raw_label.blank? || raw_label.casecmp?(user.full_name.strip)
        nil
      else
        raw_label
      end

    amount_usd = parse_amount_usd(params[:amount_usd])
    investor_since = parse_investor_since(params[:investor_since])

    investment = Investment.new(
      user: user,
      project: project,
      bitcoin_address: params[:bitcoin_address],
      company_or_nickname: company_or_nickname,
      amount_usd: amount_usd,
      investor_since: investor_since
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
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def require_super_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_assign_investments?
  end

  def parse_amount_usd(value)
    return 50_000 if value.blank?
    BigDecimal(value.to_s)
  rescue ArgumentError
    50_000
  end

  def parse_investor_since(value)
    return Date.current if value.blank?
    Date.parse(value.to_s)
  rescue ArgumentError
    Date.current
  end
end