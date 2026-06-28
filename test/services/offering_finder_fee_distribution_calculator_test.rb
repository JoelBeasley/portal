require "test_helper"

class OfferingFinderFeeDistributionCalculatorTest < ActiveSupport::TestCase
  setup do
    @offering = Offering.create!(
      name: "Distribution Test",
      carried_interest: 20,
      carried_interest_bitcoin_address: "bc1qtestaddress000000000000000000000000000"
    )
  end

  test "calculates 5 percent of carried interest btc" do
    amount = OfferingFinderFeeDistributionCalculator.calculate(offering: @offering, total_btc: "10")

    assert_equal BigDecimal("0.1"), amount
    assert_equal "0.10000000", OfferingFinderFeeDistributionCalculator.format_amount(amount)
  end

  test "returns zero when carried interest is not set" do
    offering = Offering.create!(name: "No Carried Interest")

    amount = OfferingFinderFeeDistributionCalculator.calculate(offering: offering, total_btc: "10")

    assert_equal BigDecimal("0"), amount
  end

  test "returns zero for blank total btc" do
    amount = OfferingFinderFeeDistributionCalculator.calculate(offering: @offering, total_btc: "")

    assert_equal BigDecimal("0"), amount
  end
end
