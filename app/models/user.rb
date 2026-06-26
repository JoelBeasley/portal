class User < ApplicationRecord
  audited except: %i[
    encrypted_password
    reset_password_token
    reset_password_sent_at
    remember_created_at
  ]

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
  has_associated_audits

  generates_token_for :btc_address_reminder, expires_in: 14.days do
    investments.where(bitcoin_address: [nil, ""]).count
  end

  scope :investor_directory, lambda {
    where(role: :investor).or(where(id: Investment.select(:user_id)))
  }

  scope :investors_needing_bitcoin_address, lambda {
    investor_directory
      .where.not(welcome_password_set_at: nil)
      .joins(:investments)
      .where(investments: { bitcoin_address: [nil, ""] })
      .distinct
  }

  def admin_or_super_admin?
    admin? || super_admin?
  end

  def can_access_admin_area?
    admin_or_super_admin?
  end

  def can_access_call_list?
    partner? || admin_or_super_admin?
  end

  def can_access_sites?
    partner? || admin_or_super_admin?
  end

  def invite_accepted?
    welcome_password_set_at.present?
  end

  def call_list_phone_numbers
    [
      phone,
      investor_profile&.mobile_phone_primary,
      investor_profile&.home_phone,
      investor_profile&.business_phone
    ].map { |number| number.to_s.strip }.reject(&:blank?).uniq
  end

  def bitcoin_addresses_for_call_list
    investments.map { |investment| investment.bitcoin_address.to_s.strip }.reject(&:blank?).uniq
  end

  def bitcoin_address_status
    return :no_investments if investments.empty?
    return :complete if investments_missing_bitcoin_address.empty?

    :missing
  end

  def bitcoin_address_status_label
    case bitcoin_address_status
    when :complete
      "Complete"
    when :missing
      missing_count = investments_missing_bitcoin_address.size
      "Missing (#{missing_count})"
    else
      "No investments"
    end
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

  def investments_missing_bitcoin_address
    investments.includes(:offering)
               .references(:offering)
               .where(bitcoin_address: [nil, ""])
               .order("offerings.name")
  end

  def investments_with_bitcoin_address
    investments.select { |investment| investment.bitcoin_address.present? }
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