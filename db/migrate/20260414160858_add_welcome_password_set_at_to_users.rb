class AddWelcomePasswordSetAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :welcome_password_set_at, :datetime
  end
end
