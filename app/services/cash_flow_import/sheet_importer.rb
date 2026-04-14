# frozen_string_literal: true

require "csv"

module CashFlowImport
  # Imports investors + investments from Cash Flow Portal-style CSV or Excel (.xlsx).
  # Users are matched by email; investments upsert by +cash_flow_import_id+ when present,
  # otherwise a weak match on user + project + invested_amount + date + company label, else a new row.
  class SheetImporter
    Result = Struct.new(
      :created_users,
      :updated_users,
      :created_investments,
      :updated_investments,
      :errors,
      keyword_init: true
    )

    HEADER_ALIASES = {
      "id" => :import_id,
      "investment_id" => :import_id,
      "unique_investment_id" => :import_id,
      "external_id" => :import_id,
      "cash_flow_id" => :import_id,
      "unique_profile_id" => :profile_import_id,
      "profile_name" => :profile_name,
      "profile_type" => :profile_type,
      "email" => :email,
      "e_mail" => :email,
      "email_address" => :email,
      "e_mail_address" => :email,
      "investor_email" => :email,
      "contact_email" => :email,
      "first_name" => :first_name,
      "firstname" => :first_name,
      "first" => :first_name,
      "fname" => :first_name,
      "last_name" => :last_name,
      "lastname" => :last_name,
      "last" => :last_name,
      "lname" => :last_name,
      "amount" => :invested_amount,
      "amount_usd" => :invested_amount,
      "invested_amount" => :invested_amount,
      "total_invested" => :invested_amount,
      "investment_amount" => :invested_amount,
      "funded_amount" => :funded_amount,
      "funded_date" => :investor_since,
      "funded_at" => :investor_since,
      "investor_since" => :investor_since,
      "close_date" => :investor_since,
      "signed_date" => :investor_since,
      "project" => :project_name,
      "project_name" => :project_name,
      "offering" => :project_name,
      "offering_name" => :offering_name,
      "fund" => :project_name,
      "deal" => :deal_name,
      "deal_name" => :deal_name,
      "investment_name" => :project_name,
      "legacy_offering_name" => :legacy_offering_name,
      "series_name" => :legacy_offering_name,
      "series" => :legacy_offering_name,
      "security_name" => :legacy_offering_name,
      "legal_entity_name" => :company_or_nickname,
      "legal_entity" => :company_or_nickname,
      "entity_name" => :company_or_nickname,
      "company" => :company_or_nickname,
      "nickname" => :company_or_nickname,
      "company_or_nickname" => :company_or_nickname,
      "bitcoin_address" => :bitcoin_address,
      "btc_address" => :bitcoin_address,
      "phone" => :phone,
      "phone_number" => :phone,
      "mobile" => :phone,
      "other_investor" => :other_investor_name,
      "other_investor_name" => :other_investor_name,
      "other_investor_s_email_address" => :other_investor_email,
      "date_placed" => :date_placed,
      "street_address" => :street_address,
      "address" => :street_address,
      "street" => :street_address,
      "address_line_1" => :street_address,
      "address_line1" => :street_address,
      "city" => :city,
      "state" => :state,
      "province" => :state,
      "zip" => :zip_code,
      "zip_code" => :zip_code,
      "postal_code" => :zip_code,
      "country" => :country,
      "class" => :share_class,
      "share_class" => :share_class,
      "series_class" => :share_class,
      "status" => :cash_flow_status,
      "offering_status" => :cash_flow_status,
      "investment_status" => :cash_flow_status,
      "cash_flow_status" => :cash_flow_status,
      "investment_type" => :investment_entity_type,
      "entity_type" => :investment_entity_type,
      "structure" => :investment_entity_type,
      "accreditation" => :accreditation_status,
      "accreditation_status" => :accreditation_status,
      "accredited" => :accreditation_status,
      "tax_id" => :tax_identifier,
      "tax_identifier" => :tax_identifier,
      "tax_identification_number" => :tax_identifier,
      "ein" => :ein,
      "ssn" => :ssn,
      "spouse_ssn" => :spouse_ssn,
      "federal_tax_classification" => :federal_tax_classification,
      "llc_tax_classification" => :llc_tax_classification,
      "bank_name" => :bank_name,
      "bank" => :bank_name,
      "bank_account_type" => :bank_account_type,
      "bank_account_number" => :bank_account_number,
      "account_number" => :bank_account_number,
      "bank_account" => :bank_account_number,
      "routing_number" => :bank_routing_number,
      "bank_routing_number" => :bank_routing_number,
      "routing" => :bank_routing_number,
      "aba" => :bank_routing_number,
      "distribution_method" => :distribution_method,
      "payout_method" => :distribution_method,
      "percent_of_class_or_bucket_by_target_raise" => :percent_of_class_or_bucket_by_target_raise,
      "percent_of_class_by_total_raised" => :percent_of_class_by_total_raised,
      "ownership_percentage" => :ownership_percentage,
      "shares_owned" => :shares_owned,
      "investment_fees" => :investment_fees,
      "investment_fees_funded" => :investment_fees_funded,
      "distributed_amount" => :distributed_amount,
      "reinvest_distributions" => :reinvest_distributions,
      "accrued_preferred_return" => :accrued_preferred_return,
      "unpaid_preferred_return" => :unpaid_preferred_return,
      "preferred_return_start_date" => :preferred_return_start_date,
      "ach_investment_funding_status" => :ach_investment_funding_status,
      "waitlist_status" => :waitlist_status,
      "investment_approval" => :investment_approval,
      "document_signed_on" => :document_signed_on,
      "document_countersigned_on" => :document_countersigned_on,
      "funds_sent_at" => :funds_sent_at,
      "funding_note" => :funding_note,
      "received_date" => :received_date,
      "owning_entity" => :owning_entity,
      "selected_sponsors" => :selected_sponsors,
      "payment_method" => :payment_method,
      "bank_for_further_credit" => :bank_for_further_credit,
      "bank_distribution_note" => :bank_distribution_note,
      "check_mailing_address" => :check_mailing_address,
      "mailing_address" => :mailing_address,
      "tax_address" => :tax_address,
      "accreditation_letter_issue_date" => :accreditation_letter_issue_date,
      "is_disregarded_entity" => :is_disregarded_entity,
      "beneficial_owner_name" => :beneficial_owner_name,
      "beneficial_owner_tax_id" => :beneficial_owner_tax_id,
      "number_of_members" => :number_of_members,
      "selected_company_member" => :selected_company_member,
      "ira_account_number" => :ira_account_number,
      "individual_ira_number" => :individual_ira_number,
      "investment_tags" => :investment_tags,
      "notes" => :notes,
      "investment_notes" => :notes,
      "comments" => :notes
    }.freeze

    # Headers that match these symbols (after normalization) map without an alias entry.
    CORE_FIELD_KEYS = (
      %i[
        import_id email first_name last_name invested_amount funded_amount investor_since project_name
        profile_import_id profile_name profile_type deal_name offering_name company_or_nickname
        other_investor_name other_investor_email date_placed bitcoin_address phone legacy_offering_name
        street_address city state zip_code country
        share_class cash_flow_status investment_entity_type accreditation_status
        percent_of_class_or_bucket_by_target_raise percent_of_class_by_total_raised ownership_percentage
        shares_owned investment_fees investment_fees_funded distributed_amount reinvest_distributions
        accrued_preferred_return unpaid_preferred_return preferred_return_start_date
        ach_investment_funding_status waitlist_status investment_approval document_signed_on
        document_countersigned_on funds_sent_at funding_note received_date owning_entity selected_sponsors
        payment_method bank_account_type bank_for_further_credit bank_distribution_note
        check_mailing_address mailing_address tax_address ein ssn spouse_ssn federal_tax_classification
        llc_tax_classification accreditation_letter_issue_date is_disregarded_entity beneficial_owner_name
        beneficial_owner_tax_id number_of_members selected_company_member ira_account_number
        individual_ira_number investment_tags
        tax_identifier bank_name bank_account_number bank_routing_number distribution_method notes
      ]
    ).freeze

    BITCOIN_REGEX = /\A(bc1|[13])[a-km-zA-HJ-NP-Z1-9]{25,34}\z/

    def initialize(default_project_id:, io: nil, string: nil, filename: "import.csv")
      @default_project_id = default_project_id.presence
      @io = io
      @string = string
      @filename = filename.to_s
    end

    def call
      errors = []
      created_users = updated_users = created_investments = updated_investments = 0

      each_parsed_row.with_index(2) do |data, row_number|
        cu, uu, ci, ui, row_errs = process_row(data)
        created_users += cu
        updated_users += uu
        created_investments += ci
        updated_investments += ui
        row_errs.each { |msg| errors << "Row #{row_number}: #{msg}" }
      rescue StandardError => e
        errors << "Row #{row_number}: #{e.message}"
      end

      Result.new(
        created_users: created_users,
        updated_users: updated_users,
        created_investments: created_investments,
        updated_investments: updated_investments,
        errors: errors
      )
    end

    private

    def each_parsed_row
      return enum_for(:each_parsed_row) unless block_given?

      each_raw_row { |raw| yield canonicalize_row(raw) }
    end

    def each_raw_row
      ext = File.extname(@filename).downcase
      if @io.present? && %w[.xlsx .xls].include?(ext)
        yield_roo_rows { |raw| yield raw }
      elsif @io.present?
        path = @io.respond_to?(:tempfile) ? @io.tempfile.path : @io.path
        csv_rows_from_path(path) { |raw| yield raw }
      elsif @string.present?
        csv_rows_from_string(@string) { |raw| yield raw }
      end
    end

    def yield_roo_rows
      require "roo"
      path = @io.respond_to?(:tempfile) ? @io.tempfile.path : @io.path
      book = Roo::Spreadsheet.open(path, extension: ext_sym)
      sheet = book.sheet(0)
      headers = sheet.row(1).map { |c| normalize_header_key(c) }
      (2..sheet.last_row).each do |i|
        row = sheet.row(i)
        cells = headers.each_with_index.map { |_, idx| normalize_cell(row[idx]) }
        yield headers.zip(cells).to_h
      end
    ensure
      book&.close
    end

    def ext_sym
      File.extname(@filename).delete(".").downcase.to_sym
    end

    def csv_rows_from_path(path)
      raw = File.read(path, mode: "rb").force_encoding("UTF-8")
      raw.sub!(/\A\xEF\xBB\xBF/, "")
      csv_rows_from_string(raw) { |raw_h| yield raw_h }
    end

    def csv_rows_from_string(str)
      table = CSV.parse(
        str,
        headers: true,
        header_converters: ->(h) { normalize_header_key(h) },
        converters: nil
      )
      table.each { |row| yield row.to_h.transform_values { |v| normalize_cell(v) } }
    end

    def normalize_header_key(value)
      value.to_s.strip.downcase.gsub(/\s+/, " ").tr(" ", "_").gsub(/[^\w]+/, "_").squeeze("_")
        .delete_prefix("_").delete_suffix("_")
    end

    def normalize_cell(value)
      case value
      when Date
        value.iso8601
      when Time, DateTime, ActiveSupport::TimeWithZone
        value.to_date.iso8601
      when Numeric
        value.is_a?(Integer) ? value.to_s : value.to_s("F")
      else
        value.to_s.strip
      end
    end

    def canonicalize_row(raw_hash)
      out = {}

      raw_hash.each do |k, v|
        key = normalize_header_key(k)
        next if key.blank?

        canon = HEADER_ALIASES[key]
        target =
          if canon
            canon
          elsif CORE_FIELD_KEYS.include?(key.to_sym)
            key.to_sym
          end

        out[target] = v if target
      end

      out
    end

    def process_row(data)
      errs = []
      import_id = data[:import_id].presence
      email = data[:email].to_s.strip.downcase
      errs << "email is required" if email.blank?
      errs << "first name is required" if data[:first_name].blank?
      errs << "last name is required" if data[:last_name].blank?
      return [0, 0, 0, 0, errs] if errs.any?

      project_name = data[:project_name].presence || data[:deal_name].presence || data[:offering_name].presence
      project = resolve_project(project_name)
      errs << "project could not be resolved (choose Project for this import on the form, or add a column whose values match a project name)" if project.blank?
      return [0, 0, 0, 0, errs] if errs.any?

      amount = parse_amount(data[:invested_amount])
      investor_since = parse_date(data[:investor_since])
      errs << "investor date is invalid" if investor_since.blank?
      return [0, 0, 0, 0, errs] if errs.any?

      counters = nil

      ApplicationRecord.transaction do
        user, was_new_user = build_user_for_import(email, data)
        unless user.save
          errs.concat(user.errors.full_messages)
          raise ActiveRecord::Rollback
        end

        investment, was_new_investment = build_investment_for_import(
          user: user,
          project: project,
          import_id: import_id,
          invested_amount: amount,
          investor_since: investor_since,
          data: data
        )
        unless investment.save
          errs.concat(investment.errors.full_messages)
          raise ActiveRecord::Rollback
        end

        uu = (!was_new_user && user.saved_changes.except("updated_at", "encrypted_password", "remember_created_at").present?) ? 1 : 0
        inv_updated = !was_new_investment && investment.saved_changes.except("updated_at").present?
        counters = {
          cu: was_new_user ? 1 : 0,
          uu: uu,
          ci: was_new_investment ? 1 : 0,
          ui: inv_updated ? 1 : 0
        }
      end

      return [0, 0, 0, 0, errs] if errs.any? || counters.nil?

      [counters[:cu], counters[:uu], counters[:ci], counters[:ui], []]
    end

    def build_user_for_import(email, data)
      user = User.find_or_initialize_by(email: email)
      was_new = user.new_record?
      user.first_name = data[:first_name].to_s.strip
      user.last_name = data[:last_name].to_s.strip
      user.role ||= :investor
      %i[phone street_address city state zip_code country].each do |attr|
        next unless data.key?(attr)
        next unless user.class.column_names.include?(attr.to_s)

        user[attr] = data[attr].to_s.strip.presence
      end

      if user.new_record?
        pwd = SecureRandom.urlsafe_base64(24)
        user.password = pwd
        user.password_confirmation = pwd
      end

      [user, was_new]
    end

    def build_investment_for_import(user:, project:, import_id:, invested_amount:, investor_since:, data:)
      company_raw = data[:company_or_nickname].presence
      bitcoin_raw = data[:bitcoin_address].presence

      investment =
        if import_id.present?
          Investment.find_or_initialize_by(cash_flow_import_id: import_id.to_s.strip)
        else
          weak_match_investment(user, project, invested_amount, investor_since, company_raw) ||
            Investment.new(user: user, project: project)
        end

      was_new = investment.new_record?
      investment.user = user
      investment.project = project
      investment.invested_amount = invested_amount
      investment.investor_since = investor_since
      investment.company_or_nickname = label_or_nil(company_raw, user)
      investment.cash_flow_import_id = import_id.to_s.strip if import_id.present?
      investment.bitcoin_address = sanitize_bitcoin(bitcoin_raw)

      cols = investment.class.column_names
      %i[
        legacy_offering_name share_class cash_flow_status investment_entity_type accreditation_status
        tax_identifier bank_name bank_account_number bank_routing_number distribution_method
        profile_import_id profile_name profile_type deal_name offering_name other_investor_name
        other_investor_email reinvest_distributions ach_investment_funding_status waitlist_status
        investment_approval owning_entity selected_sponsors payment_method bank_account_type
        bank_for_further_credit bank_distribution_note check_mailing_address mailing_address tax_address
        ein ssn spouse_ssn federal_tax_classification llc_tax_classification is_disregarded_entity
        beneficial_owner_name beneficial_owner_tax_id selected_company_member ira_account_number
        individual_ira_number investment_tags funding_note
      ].each do |attr|
        next unless data.key?(attr)
        next unless cols.include?(attr.to_s)

        investment[attr] = data[attr].to_s.strip.presence
      end

      if data.key?(:funded_amount) && cols.include?("funded_amount")
        investment.funded_amount = parse_optional_amount(data[:funded_amount])
      end

      %i[
        percent_of_class_or_bucket_by_target_raise percent_of_class_by_total_raised ownership_percentage
      ].each do |attr|
        next unless data.key?(attr)
        next unless cols.include?(attr.to_s)

        investment[attr] = parse_optional_decimal(data[attr])
      end

      %i[
        shares_owned
      ].each do |attr|
        next unless data.key?(attr)
        next unless cols.include?(attr.to_s)

        investment[attr] = parse_optional_decimal(data[attr])
      end

      %i[
        investment_fees investment_fees_funded distributed_amount accrued_preferred_return
        unpaid_preferred_return
      ].each do |attr|
        next unless data.key?(attr)
        next unless cols.include?(attr.to_s)

        investment[attr] = parse_optional_amount(data[attr])
      end

      %i[
        date_placed preferred_return_start_date document_signed_on document_countersigned_on
        received_date accreditation_letter_issue_date
      ].each do |attr|
        next unless data.key?(attr)
        next unless cols.include?(attr.to_s)

        investment[attr] = parse_optional_date(data[attr])
      end

      if data.key?(:funds_sent_at) && cols.include?("funds_sent_at")
        investment.funds_sent_at = parse_optional_datetime(data[:funds_sent_at])
      end

      if data.key?(:number_of_members) && cols.include?("number_of_members")
        investment.number_of_members = parse_optional_integer(data[:number_of_members])
      end

      if data.key?(:notes) && cols.include?("notes")
        investment.notes = data[:notes].to_s.strip.presence
      end

      [investment, was_new]
    end

    def weak_match_investment(user, project, invested_amount, investor_since, company_or_nickname)
      scope = Investment.where(user: user, project: project, invested_amount: invested_amount, investor_since: investor_since)
      label = label_or_nil(company_or_nickname, user)
      rel = label.nil? ? scope.where(company_or_nickname: nil) : scope.where(company_or_nickname: label)
      rel.first
    end

    def label_or_nil(company_or_nickname, user)
      raw = company_or_nickname.to_s.strip
      return nil if raw.blank?
      return nil if raw.casecmp?(user.full_name.strip)

      raw
    end

    def sanitize_bitcoin(addr)
      s = addr.to_s.strip
      return nil if s.blank?
      return s if s.match?(BITCOIN_REGEX)

      nil
    end

    def resolve_project(name_from_row)
      # When importing from Cash Flow, the sheet often has no usable project column.
      # If the admin picks a project in the form, every row uses that project.
      if @default_project_id.present?
        project = Project.find_by(id: @default_project_id)
        return project if project
      end

      name = name_from_row.to_s.strip
      return nil if name.blank?

      Project.where("LOWER(TRIM(name)) = ?", name.downcase.strip).first ||
        Project.where("LOWER(name) = ?", name.downcase.strip).first
    end

    def parse_amount(raw)
      s = raw.to_s.gsub(/[$,\s]/, "")
      return BigDecimal("0") if s.blank?

      BigDecimal(s)
    rescue ArgumentError
      BigDecimal("0")
    end

    def parse_optional_amount(raw)
      s = raw.to_s.gsub(/[$,\s]/, "")
      return nil if s.blank?

      BigDecimal(s)
    rescue ArgumentError
      nil
    end

    def parse_optional_decimal(raw)
      s = raw.to_s.gsub(/[,%\s]/, "")
      return nil if s.blank?

      BigDecimal(s)
    rescue ArgumentError
      nil
    end

    def parse_optional_date(raw)
      s = raw.to_s.strip
      return nil if s.blank?

      Date.parse(s)
    rescue ArgumentError
      nil
    end

    def parse_optional_datetime(raw)
      s = raw.to_s.strip
      return nil if s.blank?

      Time.zone.parse(s)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_optional_integer(raw)
      s = raw.to_s.gsub(/[,\s]/, "")
      return nil if s.blank?

      Integer(s, 10)
    rescue ArgumentError
      nil
    end

    def parse_date(raw)
      return Date.current if raw.blank?

      Date.parse(raw.to_s)
    rescue ArgumentError
      nil
    end
  end
end
