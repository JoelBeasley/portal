class InvestmentDocument < ApplicationRecord
  belongs_to :investment
  belongs_to :user
  has_one_attached :file

  enum :document_type, {
    k1: 0,
    kyc: 1,
    nda: 2,
    subscription_document: 3,
    custom: 4
  }

  validates :document_type, presence: true
  validates :custom_document_type, presence: true, if: :custom?
  validate :file_presence
  validate :user_matches_investment

  scope :tax_documents, -> {
    where(document_type: document_types[:k1])
  }

  private

  def file_presence
    errors.add(:file, "must be attached") unless file.attached?
  end

  def user_matches_investment
    return if investment.blank? || user.blank?
    return if investment.user_id == user_id

    errors.add(:user_id, "must match the selected investment's investor")
  end

  public

  def display_document_type
    return custom_document_type.to_s.strip.presence || "Custom" if custom?

    document_type.humanize
  end
end
