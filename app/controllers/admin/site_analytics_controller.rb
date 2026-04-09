class Admin::SiteAnalyticsController < ApplicationController
  require "net/http"
  require "json"

  before_action :authenticate_user!
  before_action :require_admin

  def show
  end

  def data
    token = params[:api_key].to_s.strip
    hashrate_endpoint = params[:hashrate_endpoint].to_s.strip
    rewards_endpoint = params[:rewards_endpoint].to_s.strip

    if token.blank? || hashrate_endpoint.blank? || rewards_endpoint.blank?
      render json: { error: "Missing token or endpoint." }, status: :unprocessable_entity
      return
    end

    hr_payload = fetch_braiins_json(hashrate_endpoint, token)
    rewards_payload = fetch_braiins_json(rewards_endpoint, token)

    render json: {
      hashrate: hr_payload,
      rewards: rewards_payload
    }
  rescue StandardError => e
    Rails.logger.error("Site analytics API proxy failed: #{e.class}: #{e.message}")
    render json: { error: "Failed to load Braiins API data." }, status: :bad_gateway
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def fetch_braiins_json(endpoint, token)
    uri = URI.parse(endpoint)
    unless uri.is_a?(URI::HTTPS) && uri.host == "pool.braiins.com"
      raise ArgumentError, "Endpoint must be HTTPS and hosted on pool.braiins.com"
    end

    request = Net::HTTP::Get.new(uri)
    request["Pool-Auth-Token"] = token

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Braiins returned HTTP #{response.code}"
    end

    JSON.parse(response.body)
  end
end
