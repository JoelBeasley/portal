class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_user_directory_access
  before_action :require_super_admin, only: [:update]

  def index
    @users = true_current_user.manageable_users_scope.order(:email)
  end

  def new
    @user = User.new(role: :investor)
    @projects = Project.order(:name)
    @role_options = true_current_user.creatable_roles
  end

  def create
    @user = User.new(user_create_params)
    @projects = Project.order(:name)
    @role_options = true_current_user.creatable_roles
    selected_project_id = params.dig(:user, :project_id).presence
    bitcoin_address = params.dig(:user, :bitcoin_address).to_s.strip.presence
    raw_label = params.dig(:user, :investment_label).to_s.strip
    company_or_nickname =
      if raw_label.blank? || raw_label.casecmp?(@user.full_name.strip)
        nil
      else
        raw_label
      end

    unless @role_options.include?(@user.role)
      @user.errors.add(:role, "is not allowed")
      render :new, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      @user.save!

      if selected_project_id.present?
        project = Project.find(selected_project_id)
        Investment.create!(
          user: @user,
          project: project,
          bitcoin_address: bitcoin_address,
          company_or_nickname: company_or_nickname,
          amount_usd: parse_amount_usd(params.dig(:user, :amount_usd)),
          investor_since: parse_investor_since(params.dig(:user, :investor_since))
        )
      end
    end

    redirect_to admin_users_path, notice: "User created successfully."
  rescue ActiveRecord::RecordInvalid => e
    @user.errors.add(:base, e.record.errors.full_messages.join(", ")) if e.record != @user
    render :new, status: :unprocessable_entity
  end

  def update
    user = User.find(params[:id])
    role = params.require(:user).permit(:role)[:role]

    if role.blank? || !User.roles.key?(role)
      redirect_to admin_users_path, alert: "Invalid role."
      return
    end

    if user == true_current_user && role != "super_admin"
      redirect_to admin_users_path, alert: "You cannot remove your own super admin access."
      return
    end

    user.update!(role: role)
    redirect_to admin_users_path, notice: "Updated role for #{user.email} to #{role.humanize}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_users_path, alert: e.record.errors.full_messages.join(", ")
  end

  private

  def user_create_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :first_name, :last_name)
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

  def require_user_directory_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_manage_user_directory?
  end

  def require_super_admin
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_manage_roles?
  end
end
