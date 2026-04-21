class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :first_name, :last_name, presence: true

  enum :role, { investor: 0, admin: 1, partner: 2, super_admin: 3 }

  has_one :investor_profile, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :investment_documents, dependent: :destroy
  has_many :offerings, -> { distinct }, through: :investments
  has_many :sites, through: :offerings
  has_many :started_impersonation_events, class_name: "ImpersonationEvent", foreign_key: :admin_user_id, inverse_of: :admin_user, dependent: :nullify
  has_many :targeted_impersonation_events, class_name: "ImpersonationEvent", foreign_key: :target_user_id, inverse_of: :target_user, dependent: :nullify

  def admin_or_super_admin?
    admin? || super_admin?
  end

  def can_access_admin_area?
    admin_or_super_admin?
  end

  def can_assign_investments?
    super_admin?
  end

  def can_manage_sites?
    super_admin?
  end

  def can_manage_projects?
    super_admin?
  end

  def can_manage_roles?
    super_admin?
  end

  def can_manage_user_directory?
    admin_or_super_admin?
  end

  def creatable_roles
    return self.class.roles.keys if super_admin?
    %w[investor admin]
  end

  def manageable_users_scope
    scope = User.all
    return scope if super_admin?
    scope.where.not(role: :super_admin)
  end

  def full_name
    [first_name, last_name].map { |s| s.to_s.strip }.reject(&:blank?).join(" ").presence || email
  end

  def can_impersonate?(target_user)
    return false if target_user.blank? || target_user == self

    if super_admin?
      !target_user.super_admin?
    elsif admin?
      target_user.admin? || target_user.investor?
    else
      false
    end
  end
end