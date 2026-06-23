class Admin::AuditsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  PER_PAGE = 75
  AUDITABLE_TYPES = %w[
    Investment
    InvestorProfile
    User
    Offering
    Site
    InvestmentDocument
  ].freeze

  def index
    @auditable_types = AUDITABLE_TYPES
    @audits = filtered_audits.includes(:user, :auditable).order(created_at: :desc).limit(PER_PAGE)
    @audit_users = audit_user_options
  end

  def show
    @audit = Audited::Audit.includes(:user, :auditable).find(params[:id])
  end

  private

  def filtered_audits
    scope = Audited::Audit.all
    scope = scope.where(auditable_type: params[:auditable_type]) if params[:auditable_type].in?(AUDITABLE_TYPES)
    scope = scope.where(user_id: params[:user_id], user_type: "User") if params[:user_id].present?
    scope = scope.where(action: params[:audit_action]) if params[:audit_action].in?(%w[create update destroy])
    if params[:auditable_id].present? && params[:auditable_type].in?(AUDITABLE_TYPES)
      scope = scope.where(auditable_id: params[:auditable_id], auditable_type: params[:auditable_type])
    end
    scope
  end

  def audit_user_options
    user_ids = Audited::Audit.where(user_type: "User").distinct.pluck(:user_id).compact
    User.where(id: user_ids).order(:email)
  end

  def require_admin
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_access_admin_area?
  end
end
