class Admin::InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def assign
    @investment = Investment.new
    @users = User.where(role: [:investor, :admin]).order(:email)  # Admins can also be investors
    @sites = Site.all.order(:name)
  end

  def create_assignment
    user = User.find(params[:user_id])
    site_ids = params[:site_ids]&.reject(&:blank?) || []

    if site_ids.empty?
      redirect_to assign_admin_investments_path, alert: "Please select at least one site."
      return
    end

    dropbox_path = "/Bitcoin_Investments/inv_#{Time.current.to_i}_#{user.email.parameterize}"

    investment = Investment.new(
      user: user,
      dropbox_path: dropbox_path,
      bitcoin_address: params[:bitcoin_address]
    )

    if investment.save
      site_ids.each do |site_id|
        InvestmentSite.create!(investment: investment, site: Site.find(site_id))
      end

      begin
        DropboxService.new.create_folder(dropbox_path)
      rescue => e
        Rails.logger.error "Dropbox folder creation failed: #{e.message}"
      end

      redirect_to admin_sites_path, 
                  notice: "Investment created for #{user.email} with #{site_ids.size} site(s) and Dropbox folder."
    else
      redirect_to assign_admin_investments_path, alert: investment.errors.full_messages.join(", ")
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.admin?
  end
end