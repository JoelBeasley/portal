class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_FROM_EMAIL", "partners@sovrncapital.com")
  layout "mailer"
end
