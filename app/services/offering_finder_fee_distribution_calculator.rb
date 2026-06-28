class OfferingFinderFeeDistributionCalculator
  FINDER_FEE_PERCENT = 5
  BTC_PRECISION = 8

  def self.calculate(offering:, total_btc:)
    new(offering: offering, total_btc: total_btc).amount
  end

  def self.format_amount(amount)
    Kernel.format("%.#{BTC_PRECISION}f", amount.round(BTC_PRECISION))
  end

  def initialize(offering:, total_btc:)
    @offering = offering
    @total_btc = parse_total_btc(total_btc)
  end

  def amount
    return BigDecimal("0") if total_btc <= 0

    carried_rate = offering.carried_interest.to_d
    return BigDecimal("0") if carried_rate.zero?

    carried_btc = total_btc * (carried_rate / 100)
    (carried_btc * (BigDecimal(FINDER_FEE_PERCENT.to_s) / 100)).round(BTC_PRECISION)
  end

  private

  attr_reader :offering, :total_btc

  def parse_total_btc(raw)
    return BigDecimal("0") if raw.blank?

    BigDecimal(raw.to_s)
  rescue ArgumentError
    BigDecimal("0")
  end
end
