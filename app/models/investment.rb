class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :offering
  belongs_to :investor_profile, optional: true
  has_many :sites, through: :offering
  has_many_attached :documents
  has_many :investment_documents, dependent: :destroy

  validates :bitcoin_address,
            format: { with: /\A(bc1|[13])[a-km-zA-HJ-NP-Z1-9]{25,34}\z/, message: "must be a valid Bitcoin address" },
            allow_blank: true

  before_validation :sync_investor_profile_from_user
  validate :investor_profile_matches_user

  def list_title
    full_name = user.full_name
    nickname = company_or_nickname.to_s.strip
    return full_name if nickname.blank? || ["-", "--"].include?(nickname)

    "#{full_name} (#{nickname})"
  end

  def investor_profile_for_display
    investor_profile || user&.investor_profile
  end

  private

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