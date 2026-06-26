class Site < ApplicationRecord
  audited

  belongs_to :offering

  enum :status, {
    operating: 0,
    construction: 1,
    development: 2,
    paused: 3
  }, prefix: true

  normalizes :braiins_pool_auth_token, with: ->(v) { v.to_s.strip.presence }

  validates :default_current_machines, numericality: { only_integer: true, greater_than: 0 }
  validates :default_projected_machines, numericality: { only_integer: true, greater_than: 0 }
end
