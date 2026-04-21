class AddInvestorProfileToInvestments < ActiveRecord::Migration[8.1]
  def up
    add_reference :investments, :investor_profile, foreign_key: true, index: true

    say_with_time "Backfill investments.investor_profile_id from users" do
      Investment.find_each do |inv|
        profile = InvestorProfile.find_by(user_id: inv.user_id)
        next unless profile

        inv.update_column(:investor_profile_id, profile.id)
      end
    end
  end

  def down
    remove_reference :investments, :investor_profile, foreign_key: true
  end
end
