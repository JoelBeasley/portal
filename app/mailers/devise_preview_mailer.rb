class DevisePreviewMailer < ApplicationMailer
  def reset_password_preview(recipient = "preview@example.com")
    @resource = User.first || User.new(email: recipient, first_name: "Sample", last_name: "Investor")
    @token = "preview-token-123456"

    mail(to: recipient, subject: "Preview: Reset your password")
  end
end
