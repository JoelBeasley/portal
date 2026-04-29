class RenameSizeKwToSizeMwOnSites < ActiveRecord::Migration[8.1]
  def up
    rename_column :sites, :size_kw, :size_mw
    change_column :sites, :size_mw, :decimal, precision: 10, scale: 3

    execute <<~SQL.squish
      UPDATE sites
      SET size_mw = ROUND(size_mw / 1000.0, 3)
      WHERE size_mw IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE sites
      SET size_mw = ROUND(size_mw * 1000.0, 2)
      WHERE size_mw IS NOT NULL
    SQL

    change_column :sites, :size_mw, :decimal, precision: 10, scale: 2
    rename_column :sites, :size_mw, :size_kw
  end
end
