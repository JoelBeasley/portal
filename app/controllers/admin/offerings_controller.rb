require "csv"

class Admin::OfferingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_offerings_access
  before_action :require_super_admin, only: [:new, :create, :edit, :update]
  before_action :set_offering, only: [:show, :edit, :update, :export_addresses, :preview_export_addresses]

  def index
    @offerings = Offering.includes(:sites, investments: :user).order(:name)
  end

  def show
    load_show_associations
    @show_preview = false
  end

  def new
    @offering = Offering.new
  end

  def edit; end

  def create
    @offering = Offering.new(offering_params)
    if @offering.save
      redirect_to admin_offering_path(@offering), notice: "Offering created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @offering.update(offering_params)
      redirect_to admin_offering_path(@offering), notice: "Offering updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def export_addresses
    rows = build_export_rows(params[:btc_amount])

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["name", "bitcoin_address", "btc_amount", "offering_name"]
      rows.each do |row|
        csv << [row[:name], row[:bitcoin_address], row[:btc_amount], row[:offering_name]]
      end
    end

    date_fragment = "#{Date.current.month}_#{Date.current.day}_#{Date.current.year}"
    send_data csv_data,
              filename: "address_export_#{date_fragment}.csv",
              type: "text/csv"
  rescue OfferingBtcExportCalculator::Error => e
    load_show_associations
    flash.now[:alert] = e.message
    render :show, status: :unprocessable_entity
  end

  def preview_export_addresses
    load_show_associations
    @preview_btc_amount = params[:btc_amount]
    export_rows = build_export_rows(params[:btc_amount])
    @preview_total_btc_amount = OfferingBtcExportCalculator.format_btc_amount(
      export_rows.sum { |row| BigDecimal(row[:btc_amount]) }
    )
    @preview_rows = export_rows
    @show_preview = true
    render :show
  rescue OfferingBtcExportCalculator::Error => e
    load_show_associations
    @preview_btc_amount = params[:btc_amount]
    @preview_error = e.message
    @show_preview = true
    render :show, status: :unprocessable_entity
  end

  private

  def set_offering
    @offering = Offering.find(params[:id])
  end

  def load_show_associations
    @sites = @offering.sites.order(:name)
    investment_order = "users.email ASC, investments.id ASC"
    @investor_investments =
      @offering.active_investments
        .joins(:user)
        .includes(:user)
        .order(investment_order)
    @archived_investments =
      @offering.archived_investments
        .joins(:user)
        .includes(:user)
        .order(investment_order)
  end

  def require_offerings_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_access_offerings?
  end

  def require_super_admin
    redirect_to admin_offerings_path, alert: "Access denied." unless current_user.can_manage_projects?
  end

  def offering_params
    params.require(:offering).permit(
      :name,
      :description,
      :carried_interest,
      :carried_interest_bitcoin_address
    )
  end

  def build_export_rows(btc_amount)
    investments = @offering.active_investments.includes(:user).order(created_at: :desc)
    calculator = OfferingBtcExportCalculator.new(
      offering: @offering,
      total_btc: btc_amount,
      investments: investments
    )

    calculator.rows.map do |row|
      {
        name: row.name,
        bitcoin_address: row.bitcoin_address,
        btc_amount: OfferingBtcExportCalculator.format_btc_amount(row.btc_amount),
        offering_name: @offering.name
      }
    end
  end
end
