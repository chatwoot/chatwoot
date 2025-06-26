class HealthController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def check
    health_report = services.transform_values { |checker| safe_result(&checker) }

    status_code = health_report.values.all? { |v| v[:status] } ? :ok : :service_unavailable
    render json: health_report, status: status_code
  end

  private

  def services
    base_services = {
      rails:    -> { true },
      database: -> { self.class.db_healthy? },
      redis:    -> { self.class.redis_healthy? },
      sidekiq:  -> { self.class.sidekiq_healthy? }
    }

    if Rails.env.development?
      base_services[:vite] = -> { self.class.vite_healthy! }
      base_services[:mailhog] = -> { self.class.mailhog_healthy! }
    end

    base_services
  end

  def safe_result
    value = yield
    { status: value, error: nil }
  rescue => e
    { status: false, error: e.message }
  end

  def self.db_healthy?
    ActiveRecord::Base.connection.active?
  end

  def self.redis_healthy?
    redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379')
    options = { url: redis_url }

    redis_password = ENV['REDIS_PASSWORD']
    options[:password] = redis_password if redis_password.present?

    Redis.new(**options).ping == 'PONG'
  end

  def self.sidekiq_healthy?
    require 'sidekiq/api'
    raise 'No Sidekiq processes found' if Sidekiq::ProcessSet.new.to_a.empty?
    true
  end

  def self.vite_healthy!
    check_http_services(
      ['http://localhost:3036', 'http://vite:3036'],
      method: :head
    )
  end

  def self.mailhog_healthy!
    check_http_services(
      ['http://localhost:8025', 'http://mailhog:8025'],
      method: :get
    )
  end

  def self.check_http_services(urls, method:)
    errors = []

    urls.each do |url|
      uri = URI.parse(url)
      begin
        Net::HTTP.start(uri.host, uri.port, open_timeout: 2, read_timeout: 2) do |http|
          response = http.send(method, uri.request_uri)
          return true if response.is_a?(Net::HTTPOK) || response.is_a?(Net::HTTPRedirection) || response.is_a?(Net::HTTPNoContent)
          errors << "Got response #{response.code} #{response.message} from #{url}"
        end
      rescue => e
        errors << "#{url} - #{e.class}: #{e.message}"
      end
    end

    raise "Unreachable. Tried: #{errors.join(' | ')}"
  end
end
