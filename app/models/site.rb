class Site < ApplicationRecord
  belongs_to :offering

  normalizes :braiins_pool_auth_token, with: ->(v) { v.to_s.strip.presence }
end
