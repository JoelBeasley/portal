class Users::PasswordsController < Devise::PasswordsController
  def update
    super do |resource|
      next unless resource.errors.empty?
      next unless resource.respond_to?(:welcome_password_set_at)
      next if resource.welcome_password_set_at.present?

      resource.update_column(:welcome_password_set_at, Time.current)
    end
  end
end
