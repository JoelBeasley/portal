require "csv"

class Admin::OfferingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :require_super_admin, only: [:new, :create]

  def index
    @offerings = Offering.includes(:sites, investments: :user).order(:name)
  end

  def show
    @offering = Offering.find(params[:id])
    @sites = @offering.sites.order(:name)
    @investments = @offering.investments.includes(:user).order(created_at: :desc)
    @investors = @offering.users.order(:email)
  end

  def new
    @offering = Offering.new
  end

  def create
    @offering = Offering.new(offering_params)
    if @offering.save
      redirect_to admin_offering_path(@offering), notice: "Offering created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def export_addresses
    offering = Offering.find(params[:id])
    investments = offering.investments.includes(:user).order(created_at: :desc)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["name", "bitcoin_address", "offering_name"]
      investments.each do |investment|
        csv << [investment.user.full_name, investment.bitcoin_address, offering.name]
      end
    end

    date_fragment = "#{Date.current.month}_#{Date.current.day}_#{Date.current.year}"
    send_data csv_data,
              filename: "address_export_#{date_fragment}.csv",
              type: "text/csv"
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def require_super_admin
    redirect_to admin_offerings_path, alert: "Access denied." unless current_user.can_manage_projects?
  end

  def offering_params
    params.require(:offering).permit(:name, :description)
  end
end
