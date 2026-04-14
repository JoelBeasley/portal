# frozen_string_literal: true

class RenameAmountUsdToInvestedAmount < ActiveRecord::Migration[8.1]
  def change
    rename_column :investments, :amount_usd, :invested_amount
  end
end
