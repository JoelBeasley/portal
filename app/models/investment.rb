class Investment < ApplicationRecord
  BITCOIN_ADDRESS_REGEX = /\A(?:[13][a-km-zA-HJ-NP-Z1-9]{25,34}|bc1[a-z0-9]{25,87})\z/

  READONLY_ATTRIBUTES = %i[id created_at updated_at investor_profile_id].freeze
  PERMITTED_ATTRIBUTES = (column_names.map(&:to_sym) - READONLY_ATTRIBUTES).freeze

  belongs_to :user
  belongs_to :offering
  belongs_to :investor_profile, optional: true
  has_many :sites, through: :offering
  has_many_attached :documents
  has_many :investment_documents, dependent: :destroy

  validates :bitcoin_address,
            format: { with: BITCOIN_ADDRESS_REGEX, message: "must be a valid Bitcoin address" },
            allow_blank: true

  before_validation :sync_investor_profile_from_user
  validate :investor_profile_matches_user

  def list_title
    full_name = user.full_name
    nickname = display_company_or_nickname
    return full_name if nickname.blank?

    "#{full_name} (#{nickname})"
  end

  def display_company_or_nickname
    resolved_display_label(company_or_nickname)
  end

  def display_profile_name
    resolved_display_label(profile_name)
  end

  def investor_profile_for_display
    investor_profile || user&.investor_profile
  end

  private

  def resolved_display_label(investment_value)
    investment_label = InvestorProfile.normalize_label(investment_value)
    profile_label = InvestorProfile.normalize_label(investor_profile_for_display&.nickname)

    if user.investments.count == 1 && profile_label.present?
      return profile_label
    end

    investment_label || profile_label
  end

  def sync_investor_profile_from_user
    return if user_id.blank?

    prof = user&.investor_profile
    self.investor_profile_id = prof&.id
  end

  def investor_profile_matches_user
    return if investor_profile_id.blank?
    return if investor_profile&.user_id == user_id

    errors.add(:investor_profile, "must belong to this investment's user")
  end
end