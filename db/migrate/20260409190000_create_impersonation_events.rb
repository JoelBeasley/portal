class CreateImpersonationEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :impersonation_events do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
