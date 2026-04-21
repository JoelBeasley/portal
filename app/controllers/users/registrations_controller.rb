class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  protected

  # Allow profile updates without requiring current password.
  # Keep password changes protected by current password.
  def update_resource(resource, params)
    if params[:password].present? || params[:password_confirmation].present?
      resource.update_with_password(params)
    else
      resource.update_without_password(params.except(:current_password))
    end
  end

  def after_update_path_for(_resource)
    edit_user_registration_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name phone])
  end
end
