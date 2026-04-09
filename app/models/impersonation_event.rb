class ImpersonationEvent < ApplicationRecord
  belongs_to :admin_user, class_name: "User"
  belongs_to :target_user, class_name: "User"

  scope :active, -> { where(ended_at: nil) }
end
