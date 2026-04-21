class AddDetailsToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :location, :string
    add_column :sites, :power_source, :string
    add_column :sites, :model, :string
    add_column :sites, :size_kw, :integer
    add_column :sites, :status, :integer
    add_column :sites, :power_cost, :decimal, precision: 10, scale: 4
  end
end
