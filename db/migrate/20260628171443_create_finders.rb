class CreateFinders < ActiveRecord::Migration[8.1]
  def change
    create_table :finders do |t|
      t.references :offering, null: false, foreign_key: true
      t.string :name, null: false
      t.string :btc_address
      t.decimal :fee_percent, precision: 5, scale: 2, null: false

      t.timestamps
    end
  end
end
