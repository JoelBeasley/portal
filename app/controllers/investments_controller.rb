class InvestmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @investments = current_user.investments.includes(:sites)
  end

  def show_documents
    @investment = current_user.investments.find(params[:id])
    @documents = DropboxService.new.list_documents(@investment.dropbox_path)
  end

  def update
    @investment = current_user.investments.find(params[:id])

    if @investment.update(investment_params)
      redirect_to documents_investment_path(@investment),
                  notice: "Bitcoin payout address updated successfully."
    else
      @documents = DropboxService.new.list_documents(@investment.dropbox_path)
      render :show_documents, status: :unprocessable_entity
    end
  end

  private

  def investment_params
    params.require(:investment).permit(:bitcoin_address)
  end
end