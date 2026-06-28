require "test_helper"

class OfferingFinderFeeExportCalculatorTest < ActiveSupport::TestCase
  setup do
    @offering = Offering.create!(name: "Export Test Offering")
    @offering.finders.create!(name: "Finder A", fee_percent: 60)
    @offering.finders.create!(name: "Finder B", fee_percent: 40)
    @finders = @offering.finders.order(:name, :id)
  end

  test "splits total btc by fee percent" do
    calculator = OfferingFinderFeeExportCalculator.new(
      offering: @offering,
      total_btc: "1.0",
      finders: @finders
    )

    rows = calculator.rows
    assert_equal 2, rows.size
    assert_equal "Finder A", rows[0].name
    assert_equal "0.60000000", OfferingFinderFeeExportCalculator.format_btc_amount(rows[0].btc_amount)
    assert_equal "Finder B", rows[1].name
    assert_equal "0.40000000", OfferingFinderFeeExportCalculator.format_btc_amount(rows[1].btc_amount)
  end

  test "requires total btc amount" do
    error = assert_raises(OfferingFinderFeeExportCalculator::Error) do
      OfferingFinderFeeExportCalculator.new(
        offering: @offering,
        total_btc: "",
        finders: @finders
      )
    end
    assert_equal "Total BTC amount is required.", error.message
  end

  test "requires total btc greater than zero" do
    calculator = OfferingFinderFeeExportCalculator.new(
      offering: @offering,
      total_btc: "0",
      finders: @finders
    )

    error = assert_raises(OfferingFinderFeeExportCalculator::Error) { calculator.rows }
    assert_equal "Total BTC amount must be greater than zero.", error.message
  end

  test "requires finders with non-zero fee percent sum" do
    @offering.finders.destroy_all
    @offering.finders.create!(name: "Zero Finder", fee_percent: 0)

    calculator = OfferingFinderFeeExportCalculator.new(
      offering: @offering,
      total_btc: "1.0",
      finders: @offering.finders
    )

    error = assert_raises(OfferingFinderFeeExportCalculator::Error) { calculator.rows }
    assert_equal "No finders with fee percent to distribute.", error.message
  end
end
