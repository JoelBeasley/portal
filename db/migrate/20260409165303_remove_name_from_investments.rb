class RemoveNameFromInvestments < ActiveRecord::Migration[8.1]
  def change
    remove_column :investments, :name, :string
  end
end
