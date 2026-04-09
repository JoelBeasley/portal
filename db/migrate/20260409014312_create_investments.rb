class CreateInvestments < ActiveRecord::Migration[8.1]
  def change
    create_table :investments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :bitcoin_address
      t.string :dropbox_path

      t.timestamps
    end
  end
end
