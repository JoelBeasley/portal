class Investment < ApplicationRecord
  belongs_to :user
  has_many :investment_sites, dependent: :destroy
  has_many :sites, through: :investment_sites
end
