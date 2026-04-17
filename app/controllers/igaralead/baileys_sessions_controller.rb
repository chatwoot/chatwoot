# frozen_string_literal: true

# Proxies Baileys sidecar session management requests for the authenticated
# user's inbox. These are user-facing API v1 endpoints (not sidecar webhooks).
#
# Routes (all nested under api/v1/accounts/:account_id/inboxes/:inbox_id):
#   POST   baileys_qr_code   → start session / request QR
#   GET    baileys_status     → check session status
#   POST   baileys_disconnect → disconnect session
module Igaralead
  class BaileysSessionsController < Api::V1::Accounts::BaseController
    before_action :fetch_inbox
    before_action :validate_baileys_channel

    def qr_code
      response = sidecar_post('/sessions/start', session_id: channel.session_id, client_slug: client_slug)
      return render json: { error: 'Sidecar unavailable' }, status: :bad_gateway unless response

      render json: response, status: :ok
    end

    def status
      response = sidecar_get("/sessions/#{channel.session_id}/status?client_slug=#{client_slug}")
      return render json: { error: 'Sidecar unavailable' }, status: :bad_gateway unless response

      render json: response, status: :ok
    end

    def disconnect
      response = sidecar_post('/sessions/disconnect', session_id: channel.session_id, client_slug: client_slug)
      return render json: { error: 'Sidecar unavailable' }, status: :bad_gateway unless response

      channel.mark_disconnected if channel.respond_to?(:mark_disconnected)
      render json: response, status: :ok
    end

    private

    def fetch_inbox
      @inbox = Current.account.inboxes.find(params[:inbox_id])
    end

    def validate_baileys_channel
      return if channel.present?

      render json: { error: 'Not a Baileys WhatsApp inbox' }, status: :unprocessable_entity
    end

    def channel
      @channel ||= @inbox.channel if @inbox.channel.is_a?(Channel::BaileysWhatsapp)
    end

    def client_slug
      Current.account&.hub_client_slug
    end

    def sidecar_url
      ENV.fetch('BAILEYS_SIDECAR_URL', 'http://baileys:3500')
    end

    def sidecar_api_key
      ENV.fetch('BAILEYS_SIDECAR_API_KEY', '')
    end

    def sidecar_post(path, body = {})
      uri = URI("#{sidecar_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 5
      http.read_timeout = 15

      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json', 'X-Api-Key' => sidecar_api_key)
      request.body = body.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("[BaileysSessions] POST #{path} failed: #{e.message}")
      nil
    end

    def sidecar_get(path)
      uri = URI("#{sidecar_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri, 'X-Api-Key' => sidecar_api_key)

      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("[BaileysSessions] GET #{path} failed: #{e.message}")
      nil
    end
  end
end
