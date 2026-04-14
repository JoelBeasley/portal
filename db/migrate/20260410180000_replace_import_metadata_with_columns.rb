# frozen_string_literal: true

class ReplaceImportMetadataWithColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :investments, :import_metadata, :jsonb
    remove_column :users, :import_metadata, :jsonb

    change_table :users, bulk: true do |t|
      t.text :street_address
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :country
    end

    change_table :investments, bulk: true do |t|
      t.string :legacy_offering_name
      t.string :share_class
      t.string :cash_flow_status
      t.string :investment_entity_type
      t.string :accreditation_status
      t.decimal :funded_amount, precision: 12, scale: 2
      t.string :tax_identifier
      t.string :bank_name
      t.string :bank_account_number
      t.string :bank_routing_number
      t.string :distribution_method
      t.text :notes
    end
  end
end
