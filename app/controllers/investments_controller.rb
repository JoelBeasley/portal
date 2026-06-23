class InvestmentsController < ApplicationController
  include ManagesInvestmentBitcoinAddresses

  before_action :authenticate_user!
  before_action :set_investment, only: [:show, :documents, :update, :upload_document]

  def index
    load_investments_index_data
  end

  def update_bitcoin_addresses
    unless current_user.investor?
      redirect_to root_path, alert: "Access denied."
      return
    end

    @submitted_bitcoin_addresses = investment_bitcoin_address_params

    unless any_submitted_bitcoin_address?(@submitted_bitcoin_addresses)
      load_investments_index_data
      flash.now[:alert] = "Please enter a Bitcoin payout address for at least one investment."
      render :index, status: :unprocessable_entity
      return
    end

    @investment_bitcoin_errors = validate_investment_bitcoin_addresses(current_user, @submitted_bitcoin_addresses)

    if @investment_bitcoin_errors.empty?
      apply_investment_bitcoin_addresses!(current_user, @submitted_bitcoin_addresses)
      redirect_to root_path, notice: "Bitcoin payout address#{'es' unless saved_address_count(@submitted_bitcoin_addresses) == 1} saved successfully."
      return
    end

    load_investments_index_data
    render :index, status: :unprocessable_entity
  end

  def show
    @typed_documents = @investment.investment_documents.with_attached_file.order(created_at: :desc)
    @investor_profile = @investment.investor_profile_for_display
  end

  def documents
    @documents = @investment.documents.includes(:blob)
    @typed_documents = @investment.investment_documents.with_attached_file.order(created_at: :desc)
  end

  def update
    if @investment.update(investment_params)
      redirect_to documents_investment_path(@investment),
                  notice: "Bitcoin payout address updated successfully."
    else
      @documents = @investment.documents.includes(:blob)
      @typed_documents = @investment.investment_documents.with_attached_file.order(created_at: :desc)
      render :documents, status: :unprocessable_entity
    end
  end

  def upload_document
    unless current_user.can_access_admin_area?
      redirect_to investment_path(@investment), alert: "Access denied."
      return
    end

    upload = params[:document]
    if upload.blank?
      redirect_to investment_path(@investment), alert: "Please choose a file to upload."
      return
    end

    @investment.documents.attach(
      io: upload.tempfile,
      filename: upload.original_filename,
      content_type: upload.content_type,
      key: document_key_for(upload.original_filename)
    )

    redirect_to investment_path(@investment), notice: "Document uploaded successfully."
  end

  private

  def load_investments_index_data
    @investments = current_user.investments.includes(offering: :sites)
    @tax_documents = current_user.investment_documents
                                 .tax_documents
                                 .includes(investment: :offering)
                                 .with_attached_file
                                 .order(created_at: :desc)
    @investments_missing_bitcoin_address =
      if current_user.investor?
        current_user.investments_missing_bitcoin_address
      else
        []
      end
  end

  def saved_address_count(submitted_addresses)
    submitted_addresses.count { |_, address| address.to_s.strip.present? }
  end

  def investment_params
    params.require(:investment).permit(:bitcoin_address)
  end

  def set_investment
    includes = [:offering, :investor_profile, :sites, :investment_documents, { user: :investor_profile }]
    @investment =
      if current_user.can_access_admin_area?
        Investment.includes(*includes).find(params[:id])
      else
        current_user.investments.includes(*includes).find(params[:id])
      end
  end

  def document_key_for(filename)
    extension = File.extname(filename.to_s)
    basename = File.basename(filename.to_s, extension).parameterize.presence || "document"
    "#{Rails.env}/investments/#{@investment.id}/#{SecureRandom.uuid}-#{basename}#{extension.downcase}"
  end
end