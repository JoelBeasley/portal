class Finder < ApplicationRecord
  audited associated_with: :offering

  belongs_to :offering

  validates :name, presence: true
  validates :fee_percent,
            presence: true,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :btc_address,
            format: { with: Investment::BITCOIN_ADDRESS_REGEX, message: "must be a valid Bitcoin address" },
            allow_blank: true
end
