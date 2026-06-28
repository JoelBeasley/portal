require "test_helper"

class FinderTest < ActiveSupport::TestCase
  setup do
    @offering = Offering.create!(name: "Finder Test Offering")
    @finder = @offering.finders.build(
      name: "Jane Finder",
      btc_address: "bc1qtestaddress000000000000000000000000000",
      fee_percent: 25.50
    )
  end

  test "valid with required attributes" do
    assert @finder.valid?
    assert @finder.save
  end

  test "requires name" do
    @finder.name = nil
    assert_not @finder.valid?
    assert_includes @finder.errors[:name], "can't be blank"
  end

  test "requires fee_percent" do
    @finder.fee_percent = nil
    assert_not @finder.valid?
    assert_includes @finder.errors[:fee_percent], "can't be blank"
  end

  test "fee_percent must be between 0 and 100" do
    @finder.fee_percent = -0.01
    assert_not @finder.valid?

    @finder.fee_percent = 100.01
    assert_not @finder.valid?

    @finder.fee_percent = 0
    assert @finder.valid?

    @finder.fee_percent = 100
    assert @finder.valid?
  end

  test "btc_address is optional" do
    @finder.btc_address = nil
    assert @finder.valid?
  end

  test "btc_address must be valid when present" do
    @finder.btc_address = "not-a-valid-address"
    assert_not @finder.valid?
    assert_includes @finder.errors[:btc_address], "must be a valid Bitcoin address"
  end

  test "destroyed when offering is destroyed" do
    @finder.save!
    assert_difference "Finder.count", -1 do
      @offering.destroy
    end
  end
end
