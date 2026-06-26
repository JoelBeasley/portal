class AddCarriedInterestToOfferings < ActiveRecord::Migration[8.1]
  def change
    add_column :offerings, :carried_interest, :decimal, precision: 5, scale: 2
    add_column :offerings, :carried_interest_bitcoin_address, :string
  end
end
