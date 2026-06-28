class Offering < ApplicationRecord
  audited

  has_many :sites, dependent: :destroy
  has_many :finders, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :active_investments, -> { active }, class_name: "Investment"
  has_many :archived_investments, -> { archived }, class_name: "Investment"
  has_many :users, -> { distinct }, through: :investments

  validates :name, presence: true
  validates :carried_interest,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_nil: true }
  validates :carried_interest_bitcoin_address,
            format: { with: Investment::BITCOIN_ADDRESS_REGEX, message: "must be a valid Bitcoin address" },
            allow_blank: true
  validate :carried_interest_bitcoin_address_required_when_carried_interest_set

  private

  def carried_interest_bitcoin_address_required_when_carried_interest_set
    return if carried_interest.blank? || carried_interest.to_d.zero?
    return if carried_interest_bitcoin_address.present?

    errors.add(:carried_interest_bitcoin_address, "must be present when carried interest is set")
  end
end
