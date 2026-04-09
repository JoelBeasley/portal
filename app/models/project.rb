class Project < ApplicationRecord
  has_many :sites, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :users, -> { distinct }, through: :investments

  validates :name, presence: true
end
