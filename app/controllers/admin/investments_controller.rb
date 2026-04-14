class Admin::InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :require_super_admin, only: [:assign, :create_assignment, :import, :create_import]

  def assign
    @investment = Investment.new
    @users = User.where(role: [:investor, :admin, :super_admin]).order(:email)
    @offerings = Offering.order(:name)
  end

  def import
    @offerings = Offering.order(:name)
  end

  def create_import
    file = params[:import_file]
    text = params[:import_text].to_s
    default_offering_id = params[:default_offering_id].presence

    if file.blank? && text.strip.blank?
      redirect_to import_admin_investments_path, alert: "Add a file or paste CSV/TSV data."
      return
    end

    filename = file&.original_filename || "paste.csv"
    io = file.presence

    result = CashFlowImport::SheetImporter.new(
      default_offering_id: default_offering_id,
      io: io,
      string: (text.strip.presence unless io),
      filename: filename
    ).call

    parts = [
      "#{result.created_users} new user(s)",
      "#{result.updated_users} user update(s)",
      "#{result.created_investments} new investment(s)",
      "#{result.updated_investments} investment update(s)"
    ]
    summary = "Import: #{parts.join(', ')}."

    if result.errors.any?
      # Do not stash errors in the session — cookie store maxes out (~4KB).
      @offerings = Offering.order(:name)
      @import_errors = result.errors.first(500)
      @import_text = text
      flash.now[:notice] = summary if result.created_users.positive? || result.updated_users.positive? ||
        result.created_investments.positive? || result.updated_investments.positive?
      flash.now[:alert] = "#{result.errors.size} row(s) failed. Fix and retry; details below."
      render :import, status: :unprocessable_entity
      return
    end

    redirect_to import_admin_investments_path, notice: "#{summary} All rows imported."
  end

  def create_assignment
    user = User.find(params[:user_id])
    offering = Offering.find_by(id: params[:offering_id])

    unless offering
      redirect_to assign_admin_investments_path, alert: "Please select an offering."
      return
    end

    raw_label = params[:investment_label].to_s.strip
    company_or_nickname =
      if raw_label.blank? || raw_label.casecmp?(user.full_name.strip)
        nil
      else
        raw_label
      end

    invested_amount = parse_invested_amount(params[:invested_amount])
    investor_since = parse_investor_since(params[:investor_since])

    investment = Investment.new(
      user: user,
      offering: offering,
      bitcoin_address: params[:bitcoin_address],
      company_or_nickname: company_or_nickname,
      invested_amount: invested_amount,
      investor_since: investor_since
    )

    if investment.save
      redirect_to admin_offering_path(offering),
                  notice: "Investment created for #{user.email} in offering #{offering.name}."
    else
      redirect_to assign_admin_investments_path, alert: investment.errors.full_messages.join(", ")
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def require_super_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_assign_investments?
  end

  def parse_invested_amount(value)
    return 50_000 if value.blank?
    BigDecimal(value.to_s)
  rescue ArgumentError
    50_000
  end

  def parse_investor_since(value)
    return Date.current if value.blank?
    Date.parse(value.to_s)
  rescue ArgumentError
    Date.current
  end
end