# frozen_string_literal: true

module AuditsHelper
  def audit_action_badge_class(action)
    case action
    when "create" then "bg-emerald-100 text-emerald-800"
    when "update" then "bg-blue-100 text-blue-800"
    when "destroy" then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def audit_record_label(audit)
    type = audit.auditable_type.to_s
    record = audit.auditable

    label =
      case record
      when Investment
        record.list_title
      when InvestorProfile
        record.user&.full_name || "Investor profile ##{record.id}"
      when User
        record.full_name
      when Offering, Site
        record.name
      when InvestmentDocument
        record.display_document_type
      end

    label = "#{type} ##{audit.auditable_id}" if label.blank?
    "#{type} · #{label}"
  end

  def audit_user_label(audit)
    user = audit.user
    return "System" unless user

    "#{user.full_name} (#{user.email})"
  end

  def audit_change_rows(audit)
    changes = audit.audited_changes || {}

    case audit.action
    when "create"
      changes.map { |attribute, value| [attribute, nil, value] }
    when "destroy"
      changes.map { |attribute, value| [attribute, value, nil] }
    else
      changes.map do |attribute, value|
        if value.is_a?(Array)
          [attribute, value[0], value[1]]
        else
          [attribute, nil, value]
        end
      end
    end
  end

  def format_audit_value(value)
    return "—" if value.nil?
    return "—" if value == ""

    case value
    when Time, DateTime, ActiveSupport::TimeWithZone
      l(value, format: :long)
    when Date
      l(value, format: :long)
    when TrueClass, FalseClass
      value ? "Yes" : "No"
    else
      text = value.is_a?(String) ? value.strip : value.to_s
      text.presence || "—"
    end
  end
end
