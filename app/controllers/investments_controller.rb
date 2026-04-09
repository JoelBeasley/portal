class InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_investment, only: [:show, :documents, :update, :upload_document]

  def index
    @investments = current_user.investments.includes(:sites)
  end

  def show
  end

  def documents
    @documents = @investment.documents.includes(:blob)
  end

  def update
    if @investment.update(investment_params)
      redirect_to documents_investment_path(@investment),
                  notice: "Bitcoin payout address updated successfully."
    else
      @documents = @investment.documents.includes(:blob)
      render :documents, status: :unprocessable_entity
    end
  end

  def upload_document
    unless current_user.admin?
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

  def investment_params
    params.require(:investment).permit(:bitcoin_address)
  end

  def set_investment
    @investment =
      if current_user.admin?
        Investment.find(params[:id])
      else
        current_user.investments.find(params[:id])
      end
  end

  def document_key_for(filename)
    extension = File.extname(filename.to_s)
    basename = File.basename(filename.to_s, extension).parameterize.presence || "document"
    "#{Rails.env}/investments/#{@investment.id}/#{SecureRandom.uuid}-#{basename}#{extension.downcase}"
  end
end