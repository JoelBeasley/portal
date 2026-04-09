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
          bitcoin_address: bitcoin_address
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
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end

  def require_user_directory_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_manage_user_directory?
  end

  def require_super_admin
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_manage_roles?
  end
end
