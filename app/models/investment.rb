class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :project
  has_many :sites, through: :project
  has_many_attached :documents
  has_many :investment_documents, dependent: :destroy

  validates :bitcoin_address,
            format: { with: /\A(bc1|[13])[a-km-zA-HJ-NP-Z1-9]{25,34}\z/, message: "must be a valid Bitcoin address" },
            allow_blank: true

  def list_title
    full_name = user.full_name
    nickname = company_or_nickname.to_s.strip
    return full_name if nickname.blank? || ["-", "--"].include?(nickname)

    "#{full_name} (#{nickname})"
  end
end