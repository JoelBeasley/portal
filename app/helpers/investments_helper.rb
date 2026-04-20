# frozen_string_literal: true

module InvestmentsHelper
  MISSING = "--".freeze

  def format_investment_detail_value(inv, attr)
    case attr
    when :user_id
      u = inv.user
      u ? "#{u.full_name} · #{u.email}" : MISSING
    when :offering_id
      inv.offering&.name || MISSING
    when :invested_amount
      inv.invested_amount.present? ? number_to_currency(inv.invested_amount, precision: 0) : MISSING
    when :funded_amount
      inv.funded_amount.nil? ? MISSING : number_to_currency(inv.funded_amount, precision: 2)
    when :investor_since
      inv.investor_since.present? ? l(inv.investor_since, format: :long) : MISSING
    when :created_at, :updated_at
      t = inv.read_attribute(attr)
      t.present? ? l(t, format: :long) : MISSING
    when :profile_type
      v = inv.read_attribute(:profile_type)
      v.blank? ? MISSING : v.to_s.strip.tr("_", " ").squeeze(" ").titleize
    when :id
      inv.id.to_s
    else
      detail_string_or_dash(inv.read_attribute(attr))
    end
  end

  def detail_string_or_dash(value)
    return MISSING if value.nil?
    return MISSING if value == ""

    text = value.is_a?(String) ? value.strip : value.to_s
    text.blank? ? MISSING : text
  end

  def investment_detail_sections
    [
      {
        title: "Identity & links",
        rows: [
          ["Investor", :user_id],
          ["Offering", :offering_id],
          ["Import record ID", :cash_flow_import_id],
          ["Profile import ID", :profile_import_id],
          ["Profile name", :profile_name],
          ["Profile type", :profile_type],
          ["Deal name", :deal_name],
          ["Offering name", :offering_name],
          ["Offering / series name", :legacy_offering_name]
        ]
      },
      {
        title: "Parties & ownership",
        rows: [
          ["Company / nickname", :company_or_nickname],
          ["Other investor", :other_investor_name],
          ["Other investor email", :other_investor_email],
          ["Owning entity", :owning_entity],
          ["Selected sponsors", :selected_sponsors],
          ["Beneficial owner name", :beneficial_owner_name],
          ["Beneficial owner tax ID", :beneficial_owner_tax_id],
          ["Number of members", :number_of_members],
          ["Selected company member", :selected_company_member]
        ]
      },
      {
        title: "Capital & performance",
        rows: [
          ["Investment amount", :invested_amount],
          ["Funded amount", :funded_amount],
          ["Percent of class or bucket (target raise)", :percent_of_class_or_bucket_by_target_raise],
          ["Percent of class (total raised)", :percent_of_class_by_total_raised],
          ["Ownership percentage", :ownership_percentage],
          ["Shares owned", :shares_owned],
          ["Investment fees", :investment_fees],
          ["Investment fees funded", :investment_fees_funded],
          ["Distributed amount", :distributed_amount],
          ["Reinvest distributions", :reinvest_distributions],
          ["Accrued preferred return", :accrued_preferred_return],
          ["Unpaid preferred return", :unpaid_preferred_return]
        ]
      },
      {
        title: "Workflow & dates",
        rows: [
          ["Investor since", :investor_since],
          ["Date placed", :date_placed],
          ["Preferred return start date", :preferred_return_start_date],
          ["Document signed on", :document_signed_on],
          ["Document countersigned on", :document_countersigned_on],
          ["Funds sent at", :funds_sent_at],
          ["Received date", :received_date],
          ["Status", :cash_flow_status],
          ["ACH investment funding status", :ach_investment_funding_status],
          ["Waitlist status", :waitlist_status],
          ["Investment approval", :investment_approval],
          ["Funding note", :funding_note]
        ]
      },
      {
        title: "Structure & compliance",
        rows: [
          ["Class / share class", :share_class],
          ["Investment type", :investment_entity_type],
          ["Accreditation", :accreditation_status],
          ["Accreditation letter issue date", :accreditation_letter_issue_date],
          ["Is disregarded entity", :is_disregarded_entity],
          ["Tax identifier", :tax_identifier],
          ["EIN", :ein],
          ["SSN", :ssn],
          ["Spouse SSN", :spouse_ssn],
          ["Federal tax classification", :federal_tax_classification],
          ["LLC tax classification", :llc_tax_classification],
          ["IRA account number", :ira_account_number],
          ["Individual IRA number", :individual_ira_number]
        ]
      },
      {
        title: "Payment, banking & addresses",
        rows: [
          ["Bitcoin address", :bitcoin_address],
          ["Payment method", :payment_method],
          ["Distribution method", :distribution_method],
          ["Bank name", :bank_name],
          ["Bank account type", :bank_account_type],
          ["Bank account number", :bank_account_number],
          ["Routing number", :bank_routing_number],
          ["Bank for further credit", :bank_for_further_credit],
          ["Bank distribution note", :bank_distribution_note],
          ["Check mailing address", :check_mailing_address],
          ["Mailing address", :mailing_address],
          ["Tax address", :tax_address]
        ]
      },
      {
        title: "Metadata",
        rows: [
          ["Notes", :notes],
          ["Investment tags", :investment_tags],
          ["Created at", :created_at],
          ["Updated at", :updated_at]
        ]
      }
    ]
  end
end
