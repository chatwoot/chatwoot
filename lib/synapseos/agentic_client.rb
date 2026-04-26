# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

module Synapseos; end

class Synapseos::AgenticClient
  Result = Struct.new(:ok, :kind, :data, :message, :details, keyword_init: true) do
    def self.success(data)
      new(ok: true, kind: :ok, data: data, message: nil, details: nil)
    end

    def self.failure(kind, message, details: nil)
      new(ok: false, kind: kind, data: nil, message: message, details: details)
    end

    def ok?
      ok == true
    end

    def failure?
      !ok?
    end
  end

  DEFAULT_TIMEOUT = 30

  def initialize(base_url:, user:, password:, timeout: DEFAULT_TIMEOUT)
    raise ArgumentError, 'base_url is required' if base_url.to_s.strip.empty?
    raise ArgumentError, 'user is required' if user.to_s.strip.empty?
    raise ArgumentError, 'password is required' if password.to_s.strip.empty?

    @base_url = base_url.to_s.chomp('/')
    @user = user
    @password = password
    @timeout = timeout
  end

  def health
    request(:get, '/api/health')
  end

  def templates
    request(:get, '/api/templates')
  end

  def n8n_credentials
    request(:get, '/api/n8n/credentials')
  end

  def schema
    request(:get, '/api/schema')
  end

  def clients(account_id: nil)
    path = '/api/clients'
    path = "#{path}?account_id=#{account_id}" if account_id
    request(:get, path)
  end

  def client(slug)
    request(:get, "/api/clients/#{slug}")
  end

  def save_client(slug, payload)
    request(:put, "/api/clients/#{slug}", body: payload)
  end

  def delete_client(slug)
    request(:delete, "/api/clients/#{slug}")
  end

  def deploy_client(slug)
    request(:post, "/api/clients/#{slug}/deploy")
  end

  def undeploy_client(slug)
    request(:post, "/api/clients/#{slug}/undeploy")
  end

  def build_client(slug)
    request(:post, "/api/clients/#{slug}/build")
  end

  def sync_whatsapp_credential(slug, payload)
    request(:post, "/api/clients/#{slug}/sync-whatsapp-credential", body: payload)
  end

  def diff_chatwoot(slug)
    request(:get, "/api/clients/#{slug}/diff-chatwoot")
  end

  def snapshots(slug)
    request(:get, "/api/clients/#{slug}/snapshots")
  end

  def restore_snapshot(slug, snapshot_id)
    request(:post, "/api/clients/#{slug}/snapshots/#{snapshot_id}/restore")
  end

  private

  def connection
    @connection ||= Faraday.new(url: @base_url) do |f|
      f.request :json
      f.request :authorization, :basic, @user, @password
      f.request :retry, max: 1, interval: 0.5, backoff_factor: 2,
                        exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError]
      f.response :json, content_type: /\bjson$/
      f.options.timeout = @timeout
      f.options.open_timeout = @timeout
      f.adapter Faraday.default_adapter
    end
  end

  def request(method, path, body: nil)
    response = connection.run_request(method, path, body, nil)
    translate_response(response)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    Result.failure(:agentic_offline, e.message)
  end

  def translate_response(response)
    status = response.status
    body = response.body

    return Result.success(body) if status.between?(200, 299)
    return failure_for_known(status, body) if KNOWN_FAILURE_STATUSES.include?(status)

    fallback_failure(status, body)
  end

  KNOWN_FAILURE_STATUSES = [401, 404, 409, 422, 502, 503].freeze

  def failure_for_known(status, body)
    case status
    when 401 then Result.failure(:unauthorized, 'Invalid credentials')
    when 404 then Result.failure(:not_found, 'Resource not found')
    when 409 then Result.failure(:conflict, extract_message(body) || 'Conflict', details: body)
    when 422 then Result.failure(:validation, 'Validation error', details: body)
    when 502, 503 then Result.failure(:agentic_offline, "Upstream unavailable (#{status})")
    end
  end

  def fallback_failure(status, body)
    kind = status.between?(400, 499) ? :client_error : :server_error
    message = extract_message(body) || "#{kind.to_s.tr('_', ' ').capitalize} (#{status})"
    Result.failure(kind, message, details: body)
  end

  def extract_message(body)
    return nil unless body.is_a?(Hash)

    msg = body['detail'] || body['message'] || body['error']
    msg.is_a?(String) ? msg : nil
  end
end
