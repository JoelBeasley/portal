class OfferingFinderFeeExportCalculator
  class Error < StandardError; end

  BTC_PRECISION = 8

  Row = Struct.new(:name, :bitcoin_address, :btc_amount, keyword_init: true)

  def self.format_btc_amount(amount)
    format("%.#{BTC_PRECISION}f", amount.round(BTC_PRECISION))
  end

  def initialize(offering:, total_btc:, finders:)
    @offering = offering
    @finders = finders
    @total_btc = parse_total_btc(total_btc)
  end

  def rows
    validate!

    finder_rows
  end

  private

  attr_reader :offering, :total_btc, :finders

  def validate!
    raise Error, "Total BTC amount must be greater than zero." if total_btc <= 0
    raise Error, "No finders with fee percent to distribute." if fee_percent_sum.zero?
  end

  def fee_percent_sum
    @fee_percent_sum ||= finders.sum { |finder| finder.fee_percent.to_d }
  end

  def finder_rows
    finders.map do |finder|
      percent = finder.fee_percent.to_d
      btc_amount = round_btc(total_btc * (percent / fee_percent_sum))

      Row.new(
        name: finder.name,
        bitcoin_address: finder.btc_address,
        btc_amount: btc_amount
      )
    end
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
