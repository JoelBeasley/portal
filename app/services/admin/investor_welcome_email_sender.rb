class Admin::InvestorWelcomeEmailSender
  Result = Struct.new(:sent, :failed, keyword_init: true)

  def self.call(investors)
    sent = []
    failed = []

    investors.find_each do |investor|
      token = investor.send(:set_reset_password_token)
      Admin::InvestorWelcomeMailer.with(user: investor, token: token).welcome_email.deliver_now
      sent << investor.email
    rescue StandardError => e
      Rails.logger.error("Failed welcome email to #{investor.email}: #{e.class} - #{e.message}")
      failed << { email: investor.email, reason: friendly_error(e) }
    end

    Result.new(sent: sent, failed: failed)
  end

  def self.flash_for(result)
    sent = result.sent
    failed = result.failed

    if sent.any? && failed.empty?
      [:notice, "Sent welcome emails to #{sent.size} investor#{'s' unless sent.size == 1} who still need to set a password."]
    elsif sent.any? && failed.any?
      failed_summary = failed.map { |entry| "#{entry[:email]} (#{entry[:reason]})" }.join("; ")
      [:notice, "Sent welcome emails to #{sent.size} investor#{'s' unless sent.size == 1}. Could not send to #{failed.size}: #{failed_summary}"]
    elsif failed.any?
      failed_summary = failed.map { |entry| "#{entry[:email]} (#{entry[:reason]})" }.join("; ")
      [:alert, "Could not send welcome emails: #{failed_summary}"]
    else
      [:notice, "No pending investors found. Everyone has already set a password."]
    end
  end

  def self.friendly_error(error)
    case error
    when Postmark::InactiveRecipientError
      "inactive in Postmark (bounce, spam complaint, or suppression)"
    when Postmark::ApiInputError
      error.message
    else
      error.message
    end
  end
  private_class_method :friendly_error
end
