class Site < ApplicationRecord
  belongs_to :offering

  enum :status, {
    operating: 0,
    construction: 1,
    development: 2
  }, prefix: true

  normalizes :braiins_pool_auth_token, with: ->(v) { v.to_s.strip.presence }
end
