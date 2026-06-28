require "json"
require "net/http"

class BtcUsdPrice
  CACHE_KEY = "site_analytics/btc_usd/v1"
  CACHE_TTL = 5.minutes

  Result = Struct.new(:usd, :source, :fetched_at, keyword_init: true)

  def self.current
    new.current
  rescue StandardError => e
    Rails.logger.warn("BTC USD price fetch failed: #{e.class}: #{e.message}")
    nil
  end

  def self.cache_ttl_minutes
    (CACHE_TTL / 1.minute).to_i
  end

  def current
    payload = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      usd, source = fetch_from_public_apis
      {
        usd: usd,
        source: source,
        fetched_at: Time.current.utc.iso8601
      }
    end

    Result.new(**payload.symbolize_keys)
  end

  private

  def fetch_from_public_apis
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

    raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end
