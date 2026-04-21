class ChangeSizeKwToDecimalOnSites < ActiveRecord::Migration[8.1]
  def change
    change_column :sites, :size_kw, :decimal, precision: 10, scale: 2
  end
end
