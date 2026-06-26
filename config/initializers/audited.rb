# frozen_string_literal: true

Audited.current_user_method = :true_current_user

# Decimal columns (e.g. offering carried_interest) are BigDecimal in audit change hashes.
ActiveRecord.yaml_column_permitted_classes |= [BigDecimal]
