class OfferingBtcExportCalculator
  class Error < StandardError; end

  BTC_PRECISION = 8

  Row = Struct.new(:name, :bitcoin_address, :btc_amount, keyword_init: true)

  def self.format_btc_amount(amount)
    format("%.#{BTC_PRECISION}f", amount.round(BTC_PRECISION))
  end

  def initialize(offering:, total_btc:, investments:)
    @offering = offering
    @investments = investments
    @total_btc = parse_total_btc(total_btc)
  end

  def rows
    validate!

    investor_rows + carried_interest_rows
  end

  private

  attr_reader :offering, :total_btc, :investments

  def validate!
    raise Error, "Total BTC amount must be greater than zero." if total_btc <= 0
    raise Error, "No active investments with percent of class (total raised) to distribute." if percent_sum.zero?
    if carried_btc.positive? && offering.carried_interest_bitcoin_address.blank?
      raise Error, "Carried interest Bitcoin address is required when carried interest is set."
    end
  end

  def carried_btc
    @carried_btc ||= begin
      rate = offering.carried_interest.to_d
      return BigDecimal("0") if rate.zero?

      total_btc * (rate / 100)
    end
  end

  def investor_pool
    @investor_pool ||= total_btc - carried_btc
  end

  def percent_sum
    @percent_sum ||= investments.sum { |investment| investment.percent_of_class_by_total_raised.to_d }
  end

  def investor_rows
    investments.map do |investment|
      percent = investment.percent_of_class_by_total_raised.to_d
      btc_amount = round_btc(investor_pool * (percent / percent_sum))

      Row.new(
        name: investment.user.full_name,
        bitcoin_address: investment.bitcoin_address,
        btc_amount: btc_amount
      )
    end
  end

  def carried_interest_rows
    return [] unless carried_btc.positive?

    [
      Row.new(
        name: "Carried Interest",
        bitcoin_address: offering.carried_interest_bitcoin_address,
        btc_amount: round_btc(carried_btc)
      )
    ]
  end

  def parse_total_btc(raw)
    raise Error, "Total BTC amount is required." if raw.blank?

    BigDecimal(raw.to_s)
  rescue ArgumentError
    raise Error, "Total BTC amount must be a valid number."
  end

  def round_btc(amount)
    amount.round(BTC_PRECISION)
  end
end
