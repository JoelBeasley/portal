class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { investor: 0, admin: 1, partner: 2 }

  has_many :investments, dependent: :destroy
  has_many :investment_sites, through: :investments
  has_many :sites, through: :investment_sites

  def admin?
    role == "admin"
  end
end