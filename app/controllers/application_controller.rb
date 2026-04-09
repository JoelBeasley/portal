class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :true_current_user, :impersonating?, :impersonated_user

  def true_current_user
    @true_current_user ||= warden&.user(scope: :user)
  end

  def current_user
    return true_current_user unless true_current_user&.can_access_admin_area?
    return true_current_user unless session[:impersonated_user_id].present?

    @impersonated_user ||= User.find_by(id: session[:impersonated_user_id])
    @impersonated_user || true_current_user
  end

  def impersonating?
    true_current_user&.can_access_admin_area? && session[:impersonated_user_id].present?
  end

  def impersonated_user
    return unless impersonating?
    @impersonated_user ||= User.find_by(id: session[:impersonated_user_id])
  end
end
