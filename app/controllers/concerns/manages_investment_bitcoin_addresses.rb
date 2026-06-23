module ManagesInvestmentBitcoinAddresses
  extend ActiveSupport::Concern

  private

  def investment_bitcoin_address_params
    params.fetch(:investment_bitcoin_addresses, {}).permit!.to_h
  end

  def validate_investment_bitcoin_addresses(user, submitted_addresses)
    errors_by_id = {}
    editable_investments = user.investments_missing_bitcoin_address.index_by(&:id)

    submitted_addresses.each do |id_str, address|
      investment = editable_investments[id_str.to_i]
      next unless investment

      address = address.to_s.strip
      next if address.blank?

      investment.bitcoin_address = address
      next if investment.valid?

      errors_by_id[investment.id] = investment.errors.full_messages_for(:bitcoin_address).join(", ")
    end

    errors_by_id
  end

  def apply_investment_bitcoin_addresses!(user, submitted_addresses)
    editable_investments = user.investments_missing_bitcoin_address.index_by(&:id)

    submitted_addresses.each do |id_str, address|
      investment = editable_investments[id_str.to_i]
      next unless investment

      address = address.to_s.strip
      next if address.blank?

      investment.update!(bitcoin_address: address)
    end
  end

  def any_submitted_bitcoin_address?(submitted_addresses)
    submitted_addresses.values.any? { |address| address.to_s.strip.present? }
  end
end
