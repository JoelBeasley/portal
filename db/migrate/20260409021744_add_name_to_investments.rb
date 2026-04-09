class AddNameToInvestments < ActiveRecord::Migration[8.1]
  def change
    add_column :investments, :name, :string
  end
end
