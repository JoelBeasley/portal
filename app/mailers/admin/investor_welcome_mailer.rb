class Admin::InvestorWelcomeMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @token = params[:token]

    mail(
      to: @user.email,
      subject: "Welcome to the new Sovrn Investor Portal"
    )
  end
end
