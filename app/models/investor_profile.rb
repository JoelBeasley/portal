class InvestorProfile < ApplicationRecord
  belongs_to :user
  has_many :investments, dependent: :nullify

  # Devise default regexp; used when importing emails that may be malformed.
  IMPORT_EMAIL_RE = /\A[^@\s]+@[^@\s]+\z/

  PERMITTED_ATTRIBUTES = %i[
    name_prefix first_name middle_name last_name name_suffix nickname
    address_primary mailing_address time_zone
    home_phone mobile_phone_primary business_phone
    personal_email_primary business_email
  ].freeze

  validates :personal_email_primary, format: { with: Devise.email_regexp, allow_blank: true }
  validates :business_email, format: { with: Devise.email_regexp, allow_blank: true }

  def self.prefill_from_user!(user)
    return user.investor_profile if user.investor_profile.present?

    first_investment = user.investments.order(:created_at, :id).first
    profile = new(user: user)
    profile.assign_attributes(
      first_name: user.first_name,
      last_name: user.last_name,
      personal_email_primary: sanitize_email_for_import(user.email),
      mobile_phone_primary: user.phone.presence,
      address_primary: format_address_from_user(user)
    )
    if first_investment
      profile.nickname = first_investment.company_or_nickname.presence
      profile.mailing_address =
        first_investment.mailing_address.presence || first_investment.check_mailing_address.presence
      profile.business_email = sanitize_email_for_import(first_investment.other_investor_email)
    end
    profile.save(validate: false)
    profile
  end

  def self.sanitize_email_for_import(value)
    s = value.to_s.strip
    return if s.blank?
    return unless s.match?(IMPORT_EMAIL_RE)

    s
  end

  def self.format_address_from_user(user)
    lines = []
    lines << user.street_address if user.street_address.present?
    city_state_zip = [user.city, user.state, user.zip_code].compact.map(&:strip).reject(&:blank?).join(", ").presence
    lines << city_state_zip if city_state_zip.present?
    lines << user.country if user.country.present?
    return nil if lines.empty?

    lines.join("\n")
  end
  private_class_method :sanitize_email_for_import, :format_address_from_user
end
