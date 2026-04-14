class Admin::SiteAnalyticsController < ApplicationController
  require "digest"
  require "json"
  require "net/http"

  before_action :authenticate_user!
  before_action :require_admin

  CACHE_TTL = 6.hours
  BTC_USD_CACHE_TTL = 5.minutes

  def show
  end

  def btc_price
    cache_key = "site_analytics/btc_usd/v1"

    payload = Rails.cache.fetch(cache_key, expires_in: BTC_USD_CACHE_TTL) do
      usd, source = fetch_btc_usd_from_public_apis
      {
        usd: usd,
        source: source,
        fetched_at: Time.current.utc.iso8601
      }
    end

    render json: payload.merge(cache_ttl_minutes: (BTC_USD_CACHE_TTL / 1.minute).to_i)
  rescue StandardError => e
    Rails.logger.error("BTC USD price proxy failed: #{e.class}: #{e.message}")
    render json: { error: "Could not load BTC price." }, status: :bad_gateway
  end

  def data
    token = params[:api_key].to_s.strip
    hashrate_endpoint = params[:hashrate_endpoint].to_s.strip
    rewards_endpoint = params[:rewards_endpoint].to_s.strip

    if token.blank? || hashrate_endpoint.blank? || rewards_endpoint.blank?
      render json: { error: "Missing token or endpoint." }, status: :unprocessable_entity
      return
    end

    cache_key = [
      "site_analytics/braiins/v2",
      hashrate_endpoint,
      rewards_endpoint,
      Digest::SHA256.hexdigest(token)
    ]

    payload = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      {
        hashrate: fetch_braiins_json(hashrate_endpoint, token),
        rewards: fetch_braiins_json(rewards_endpoint, token),
        cached_at: Time.current.utc.iso8601
      }
    end

    render json: payload.merge(refresh_interval_hours: (CACHE_TTL / 1.hour).to_i)
  rescue StandardError => e
    Rails.logger.error("Site analytics API proxy failed: #{e.class}: #{e.message}")
    render json: { error: "Failed to load Braiins API data." }, status: :bad_gateway
  end

  private

  def fetch_btc_usd_from_public_apis
    fetch_coingecko_btc_usd
  rescue StandardError => e
    Rails.logger.warn("CoinGecko BTC/USD failed (#{e.class}), trying Coinbase: #{e.message}")
    fetch_coinbase_btc_usd
  end

  def fetch_coingecko_btc_usd
    uri = URI.parse("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")
    raise ArgumentError, "Invalid price API host" unless uri.is_a?(URI::HTTPS) && uri.host == "api.coingecko.com"

    data = fetch_https_json(uri)
    usd = data.dig("bitcoin", "usd")
    raise "CoinGecko response missing bitcoin.usd" if usd.nil?

    [usd.to_f, "CoinGecko"]
  end

  def fetch_coinbase_btc_usd
    uri = URI.parse("https://api.coinbase.com/v2/prices/BTC-USD/spot")
    raise ArgumentError, "Invalid price API host" unless uri.is_a?(URI::HTTPS) && uri.host == "api.coinbase.com"

    data = fetch_https_json(uri)
    amount = data.dig("data", "amount")
    raise "Coinbase response missing spot amount" if amount.nil?

    [amount.to_f, "Coinbase"]
  end

  def fetch_https_json(uri)
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.open_timeout = 5
      http.read_timeout = 12
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "HTTP #{response.code}"
    end

    JSON.parse(response.body)
  end

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
