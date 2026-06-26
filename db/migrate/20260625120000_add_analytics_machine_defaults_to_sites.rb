class AddAnalyticsMachineDefaultsToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :default_current_machines, :integer, null: false, default: 80
    add_column :sites, :default_projected_machines, :integer, null: false, default: 325
  end
end
