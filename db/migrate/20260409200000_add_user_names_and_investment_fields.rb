class AddUserNamesAndInvestmentFields < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE users
          SET
            first_name = COALESCE(NULLIF(TRIM(first_name), ''), INITCAP(SPLIT_PART(email, '@', 1))),
            last_name = COALESCE(NULLIF(TRIM(last_name), ''), 'User')
          WHERE first_name IS NULL OR first_name = '' OR last_name IS NULL OR last_name = ''
        SQL
      end
    end

    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false

    add_column :investments, :company_or_nickname, :string
    add_column :investments, :amount_usd, :decimal, precision: 12, scale: 2, null: false, default: 50_000
    add_column :investments, :investor_since, :date, null: false, default: -> { "CURRENT_DATE" }
  end

  def down
    remove_column :investments, :investor_since
    remove_column :investments, :amount_usd
    remove_column :investments, :company_or_nickname
    remove_column :users, :last_name
    remove_column :users, :first_name
  end
end
