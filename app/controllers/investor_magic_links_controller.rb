class InvestorMagicLinksController < ApplicationController
  def show
    user = User.find_by_token_for(:btc_address_reminder, params[:token])

    if user.nil?
      redirect_to new_user_session_path, alert: "This link is invalid or has expired. Please sign in with your password."
      return
    end

    unless user.investor?
      redirect_to new_user_session_path, alert: "Access denied."
      return
    end

    sign_in(user)

    if user.investments_missing_bitcoin_address.any?
      redirect_to root_path, notice: "Welcome back. Please add your Bitcoin payout address below."
    else
      redirect_to root_path, notice: "You are signed in. Your Bitcoin payout addresses are already on file."
    end
  end
end
