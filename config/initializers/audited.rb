# frozen_string_literal: true

Audited.current_user_method = :true_current_user

# Decimal columns (e.g. offering carried_interest) are BigDecimal in audit change hashes.
# Rails 8 safe YAML requires explicit permission. Restart the server after changing this file.
ActiveRecord.yaml_column_permitted_classes |= [BigDecimal]
