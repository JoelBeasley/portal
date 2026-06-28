class Admin::SiteAnalyticsController < ApplicationController
  require "digest"
  require "json"
  require "net/http"

  before_action :authenticate_user!
  before_action :require_sites_access

  CACHE_TTL = 6.hours
  BRAIINS_PROFILE_ENDPOINT = "https://pool.braiins.com/accounts/profile/json/btc/"
  BRAIINS_WORKERS_ENDPOINT = "https://pool.braiins.com/accounts/workers/json/btc/"

  def show
    @site = Site.includes(:offering).find(params[:id])
    @manage_sites = true_current_user.can_manage_sites?
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_sites_path, alert: "Site not found."
  end

  def btc_price
    price = BtcUsdPrice.current
    if price.nil?
      render json: { error: "Could not load BTC price." }, status: :bad_gateway
      return
    end

    render json: {
      usd: price.usd,
      source: price.source,
      fetched_at: price.fetched_at,
      cache_ttl_minutes: BtcUsdPrice.cache_ttl_minutes
    }
  end

  def data
    site = Site.find_by(id: params[:site_id])
    unless site
      render json: { error: "Unknown site for pool analytics." }, status: :unprocessable_entity
      return
    end

    token = params[:api_key].to_s.strip
    token = site.braiins_pool_auth_token.to_s.strip if token.blank?
    hashrate_endpoint = params[:hashrate_endpoint].to_s.strip
    rewards_endpoint = params[:rewards_endpoint].to_s.strip

    if token.blank? || hashrate_endpoint.blank? || rewards_endpoint.blank?
      msg = if params[:api_key].to_s.strip.blank? && site.braiins_pool_auth_token.blank?
              "No Braiins Pool-Auth-Token is saved for this site. Enter a token in the form or add one when editing the site."
            else
              "Missing token or endpoint."
            end
      render json: { error: msg }, status: :unprocessable_entity
      return
    end

    cache_key = [
      "site_analytics/braiins/v3",
      site.id,
      hashrate_endpoint,
      rewards_endpoint,
      Digest::SHA256.hexdigest(token)
    ].compact

    payload = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      {
        hashrate: fetch_braiins_json(hashrate_endpoint, token),
        rewards: fetch_braiins_json(rewards_endpoint, token),
        profile: fetch_braiins_json(BRAIINS_PROFILE_ENDPOINT, token),
        workers: fetch_braiins_json(BRAIINS_WORKERS_ENDPOINT, token),
        cached_at: Time.current.utc.iso8601
      }
    end

    render json: payload.merge(refresh_interval_hours: (CACHE_TTL / 1.hour).to_i)
  rescue StandardError => e
    Rails.logger.error("Site analytics API proxy failed: #{e.class}: #{e.message}")
    render json: { error: "Failed to load Braiins API data." }, status: :bad_gateway
  end

  private

  def require_sites_access
    redirect_to root_path, alert: "Access denied." unless true_current_user&.can_access_sites?
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
