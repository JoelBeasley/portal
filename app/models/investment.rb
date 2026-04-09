class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :project
  has_many :sites, through: :project
  has_many_attached :documents

  validates :bitcoin_address,
            format: { with: /\A(bc1|[13])[a-km-zA-HJ-NP-Z1-9]{25,34}\z/, message: "must be a valid Bitcoin address" },
            allow_blank: true
end