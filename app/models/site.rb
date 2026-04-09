class Site < ApplicationRecord
  has_many :investment_sites, dependent: :destroy
  has_many :investments, through: :investment_sites
end
