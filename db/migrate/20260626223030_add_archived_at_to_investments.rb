class AddArchivedAtToInvestments < ActiveRecord::Migration[8.1]
  def change
    add_column :investments, :archived_at, :datetime
    add_index :investments, :archived_at
  end
end
