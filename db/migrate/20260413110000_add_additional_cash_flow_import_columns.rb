class AddAdditionalCashFlowImportColumns < ActiveRecord::Migration[8.1]
  def change
    change_table :investments, bulk: true do |t|
      t.string :profile_import_id
      t.string :profile_name
      t.string :profile_type
      t.string :deal_name
      t.string :offering_name
      t.string :other_investor_name
      t.string :other_investor_email
      t.date :date_placed
      t.decimal :percent_of_class_or_bucket_by_target_raise, precision: 8, scale: 4
      t.decimal :percent_of_class_by_total_raised, precision: 8, scale: 4
      t.decimal :ownership_percentage, precision: 8, scale: 4
      t.decimal :shares_owned, precision: 14, scale: 4
      t.decimal :investment_fees, precision: 12, scale: 2
      t.decimal :investment_fees_funded, precision: 12, scale: 2
      t.decimal :distributed_amount, precision: 12, scale: 2
      t.string :reinvest_distributions
      t.decimal :accrued_preferred_return, precision: 12, scale: 2
      t.decimal :unpaid_preferred_return, precision: 12, scale: 2
      t.date :preferred_return_start_date
      t.string :ach_investment_funding_status
      t.string :waitlist_status
      t.string :investment_approval
      t.date :document_signed_on
      t.date :document_countersigned_on
      t.datetime :funds_sent_at
      t.text :funding_note
      t.date :received_date
      t.string :owning_entity
      t.text :selected_sponsors
      t.string :payment_method
      t.string :bank_account_type
      t.string :bank_for_further_credit
      t.text :bank_distribution_note
      t.text :check_mailing_address
      t.text :mailing_address
      t.text :tax_address
      t.string :ein
      t.string :ssn
      t.string :spouse_ssn
      t.string :federal_tax_classification
      t.string :llc_tax_classification
      t.date :accreditation_letter_issue_date
      t.string :is_disregarded_entity
      t.string :beneficial_owner_name
      t.string :beneficial_owner_tax_id
      t.integer :number_of_members
      t.string :selected_company_member
      t.string :ira_account_number
      t.string :individual_ira_number
      t.text :investment_tags
    end
  end
end
