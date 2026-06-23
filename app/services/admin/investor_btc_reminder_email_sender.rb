class Admin::InvestorBtcReminderEmailSender
  Result = Struct.new(:sent, :failed, keyword_init: true)

  def self.call(investors)
    sent = []
    failed = []

    investors.find_each do |investor|
      token = investor.generate_token_for(:btc_address_reminder)
      Admin::InvestorBtcReminderMailer.with(user: investor, token: token).reminder_email.deliver_now
      sent << investor.email
    rescue StandardError => e
      Rails.logger.error("Failed BTC reminder email to #{investor.email}: #{e.class} - #{e.message}")
      failed << { email: investor.email, reason: friendly_error(e) }
    end

    Result.new(sent: sent, failed: failed)
  end

  def self.flash_for(result)
    sent = result.sent
    failed = result.failed

    if sent.any? && failed.empty?
      [:notice, "Sent Bitcoin address reminder emails to #{sent.size} investor#{'s' unless sent.size == 1}."]
    elsif sent.any? && failed.any?
      failed_summary = failed.map { |entry| "#{entry[:email]} (#{entry[:reason]})" }.join("; ")
      [:notice, "Sent Bitcoin address reminder emails to #{sent.size} investor#{'s' unless sent.size == 1}. Could not send to #{failed.size}: #{failed_summary}"]
    elsif failed.any?
      failed_summary = failed.map { |entry| "#{entry[:email]} (#{entry[:reason]})" }.join("; ")
      [:alert, "Could not send Bitcoin address reminder emails: #{failed_summary}"]
    else
      [:notice, "No investors found who have set a password and are missing a Bitcoin payout address."]
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
