class CallListController < ApplicationController
  before_action :authenticate_user!
  before_action :require_call_list_access

  SORTABLE_COLUMNS = %w[name email phone invite btc].freeze

  def index
    @sort = params[:sort].presence_in(SORTABLE_COLUMNS) || "name"
    @direction = params[:direction] == "desc" ? "desc" : "asc"
    @investors = sorted_investors.includes(:investor_profile, investments: :offering)
  end

  private

  def require_call_list_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_access_call_list?
  end

  def sorted_investors
    scope = User.call_list_directory
    direction = @direction.upcase

    case @sort
    when "email"
      scope.order(email: @direction.to_sym)
    when "phone"
      scope.order(phone: @direction.to_sym, last_name: :asc, first_name: :asc)
    when "invite"
      scope.order(welcome_password_set_at: @direction.to_sym, last_name: :asc, first_name: :asc)
    when "btc"
      scope.order(Arel.sql("#{btc_status_sql} #{direction}, users.last_name ASC, users.first_name ASC"))
    else
      scope.order(last_name: @direction.to_sym, first_name: @direction.to_sym, email: :asc)
    end
  end

  def btc_status_sql
    <<~SQL.squish
      CASE
        WHEN NOT EXISTS (
          SELECT 1 FROM investments
          WHERE investments.user_id = users.id
            AND investments.archived_at IS NULL
        ) THEN 1
        WHEN EXISTS (
          SELECT 1 FROM investments
          WHERE investments.user_id = users.id
            AND investments.archived_at IS NULL
            AND (investments.bitcoin_address IS NULL OR investments.bitcoin_address = '')
        ) THEN 0
        ELSE 2
      END
    SQL
  end
end
