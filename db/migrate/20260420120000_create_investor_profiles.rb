class CreateInvestorProfiles < ActiveRecord::Migration[8.1]
  def up
    create_table :investor_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.string :name_prefix
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :name_suffix
      t.string :nickname

      t.text :address_primary
      t.text :mailing_address
      t.string :time_zone

      t.string :home_phone
      t.string :mobile_phone_primary
      t.string :business_phone

      t.string :personal_email_primary
      t.string :business_email

      t.timestamps
    end

    say_with_time "Prefilling investor profiles from users and first investment" do
      User.investor.find_each do |user|
        InvestorProfile.prefill_from_user!(user)
      end
    end
  end

  def down
    drop_table :investor_profiles
  end
end
