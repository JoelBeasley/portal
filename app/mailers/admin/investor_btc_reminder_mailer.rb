class Admin::InvestorBtcReminderMailer < ApplicationMailer
  def reminder_email
    @user = params[:user]
    @token = params[:token]
    @missing_count = @user.investments_missing_bitcoin_address.size

    mail(
      to: @user.email,
      subject: "Action needed: add your Bitcoin payout address"
    )
  end
end
