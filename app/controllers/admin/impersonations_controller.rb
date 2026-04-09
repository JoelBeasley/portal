class Admin::ImpersonationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_or_super_admin

  def create
    target_user = User.find(params[:user_id])
    admin_user = true_current_user

    unless admin_user.can_impersonate?(target_user)
      redirect_to admin_users_path, alert: "You cannot impersonate this user."
      return
    end

    session[:impersonated_user_id] = target_user.id
    event = ImpersonationEvent.create!(
      admin_user: admin_user,
      target_user: target_user,
      started_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    session[:impersonation_event_id] = event.id

    redirect_to root_path, notice: "Now impersonating #{target_user.email}."
  end

  def destroy
    unless session[:impersonated_user_id].present?
      redirect_to root_path, alert: "No active impersonation."
      return
    end

    if session[:impersonation_event_id].present?
      event = ImpersonationEvent.find_by(id: session[:impersonation_event_id], ended_at: nil)
      event&.update(ended_at: Time.current)
    end

    session.delete(:impersonated_user_id)
    session.delete(:impersonation_event_id)

    redirect_to admin_users_path, notice: "Stopped impersonation."
  end

  private

  def require_admin_or_super_admin
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_access_admin_area?
  end
end
