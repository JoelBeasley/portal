class DeviseMailerPreview < ActionMailer::Preview
  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(sample_user, sample_token)
  end

  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(sample_user, sample_token)
  end

  def unlock_instructions
    Devise::Mailer.unlock_instructions(sample_user, sample_token)
  end

  def password_change
    Devise::Mailer.password_change(sample_user)
  end

  def email_changed
    Devise::Mailer.email_changed(sample_user)
  end

  private

  def sample_user
    User.first || User.new(
      email: "investor@example.com",
      first_name: "Sample",
      last_name: "Investor"
    )
  end

  def sample_token
    "preview-token-123456"
  end
end
