# frozen_string_literal: true

class AddCashFlowImportFields < ActiveRecord::Migration[8.1]
  def change
    add_column :investments, :cash_flow_import_id, :string
    add_column :investments, :import_metadata, :jsonb, null: false, default: {}

    add_column :users, :phone, :string
    add_column :users, :import_metadata, :jsonb, null: false, default: {}

    add_index :investments, :cash_flow_import_id, unique: true, where: "cash_flow_import_id IS NOT NULL",
              name: "index_investments_on_cash_flow_import_id_unique"
  end
end
