class CreateInvestmentSites < ActiveRecord::Migration[8.1]
  def change
    create_table :investment_sites do |t|
      t.references :investment, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true

      t.timestamps
    end
  end
end
