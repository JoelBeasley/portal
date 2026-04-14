# frozen_string_literal: true

module InvestmentsHelper
  MISSING = "--".freeze

  def format_investment_detail_value(inv, attr)
    case attr
    when :user_id
      u = inv.user
      u ? "#{u.full_name} · #{u.email} (##{u.id})" : MISSING
    when :project_id
      inv.project&.name || MISSING
    when :invested_amount
      inv.invested_amount.present? ? number_to_currency(inv.invested_amount, precision: 0) : MISSING
    when :funded_amount
      inv.funded_amount.nil? ? MISSING : number_to_currency(inv.funded_amount, precision: 2)
    when :investor_since
      inv.investor_since.present? ? l(inv.investor_since, format: :long) : MISSING
    when :created_at, :updated_at
      t = inv.read_attribute(attr)
      t.present? ? l(t, format: :long) : MISSING
    when :id
      inv.id.to_s
    else
      detail_string_or_dash(inv.read_attribute(attr))
    end
  end

  def detail_string_or_dash(value)
    return MISSING if value.nil?
    return MISSING if value == ""

    text = value.is_a?(String) ? value.strip : value.to_s
    text.blank? ? MISSING : text
  end
end
