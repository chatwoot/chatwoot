module Baileys
  class ProviderService
    attr_reader :channel

    def initialize(channel:)
      @channel = channel
    end

    def send_message(phone_number, message)
      jid = normalize_jid(phone_number)

      payload = if message.attachments.present?
                  build_media_payload(jid, message)
                else
                  build_text_payload(jid, message)
                end

      response = post('/messages/send', payload)
      return unless response.is_a?(Hash) && response['key'].present?

      response['key']['id']
    end

    def request_qr_code
      response = post('/sessions/start', { session_id: channel.session_id })
      channel.update!(session_status: 'qr_pending') if response.is_a?(Hash)
      response
    end

    def disconnect
      post('/sessions/disconnect', { session_id: channel.session_id })
    end

    def session_status
      response = get("/sessions/#{channel.session_id}/status")
      response.is_a?(Hash) ? response['status'] : 'unknown'
    end

    def validate_provider_config?
      base_url.present?
    end

    private

    def build_text_payload(jid, message)
      payload = {
        session_id: channel.session_id,
        jid: jid,
        message: { text: message.outgoing_content }
      }
      payload[:quoted_message_id] = message.content_attributes[:in_reply_to_external_id] if message.content_attributes[:in_reply_to_external_id].present?
      payload
    end

    def build_media_payload(jid, message)
      attachment = message.attachments.first
      media_type = attachment_media_type(attachment.file_type)

      payload = {
        session_id: channel.session_id,
        jid: jid,
        message: {
          media_type => { url: attachment.download_url },
          caption: message.outgoing_content
        }.compact
      }
      payload[:quoted_message_id] = message.content_attributes[:in_reply_to_external_id] if message.content_attributes[:in_reply_to_external_id].present?
      payload
    end

    def attachment_media_type(file_type)
      case file_type
      when 'image' then :image
      when 'audio' then :audio
      when 'video' then :video
      else :document
      end
    end

    def normalize_jid(phone_number)
      number = phone_number.to_s.gsub(/[^\d]/, '')
      "#{number}@s.whatsapp.net"
    end

    def base_url
      ENV.fetch('BAILEYS_SIDECAR_URL', nil)
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json
        f.headers['Content-Type'] = 'application/json'
        f.headers['X-Api-Key'] = ENV.fetch('BAILEYS_SIDECAR_API_KEY', '')
        f.adapter Faraday.default_adapter
        f.options.timeout = 30
        f.options.open_timeout = 10
      end
    end

    def post(path, body)
      response = connection.post(path) { |req| req.body = body.to_json }
      response.body
    rescue Faraday::Error => e
      Rails.logger.error("[Baileys::ProviderService] POST #{path} failed: #{e.message}")
      nil
    end

    def get(path)
      response = connection.get(path)
      response.body
    rescue Faraday::Error => e
      Rails.logger.error("[Baileys::ProviderService] GET #{path} failed: #{e.message}")
      nil
    end
  end
end
