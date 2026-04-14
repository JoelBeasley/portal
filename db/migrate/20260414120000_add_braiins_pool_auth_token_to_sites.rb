class AddBraiinsPoolAuthTokenToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :braiins_pool_auth_token, :text
  end
end
