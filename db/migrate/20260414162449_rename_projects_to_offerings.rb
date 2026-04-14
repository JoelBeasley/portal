class RenameProjectsToOfferings < ActiveRecord::Migration[8.1]
  def change
    rename_table :projects, :offerings
    rename_column :investments, :project_id, :offering_id
    rename_column :sites, :project_id, :offering_id
  end
end
