class Investment < ApplicationRecord
  belongs_to :user
  has_many :investment_sites, dependent: :destroy
  has_many :sites, through: :investment_sites
  has_many_attached :documents

  validates :bitcoin_address,
            format: { with: /\A(bc1|[13])[a-km-zA-HJ-NP-Z1-9]{25,34}\z/, message: "must be a valid Bitcoin address" },
            allow_blank: true
end