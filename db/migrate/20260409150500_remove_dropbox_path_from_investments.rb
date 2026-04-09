class RemoveDropboxPathFromInvestments < ActiveRecord::Migration[8.1]
  def change
    remove_column :investments, :dropbox_path, :string
  end
end
