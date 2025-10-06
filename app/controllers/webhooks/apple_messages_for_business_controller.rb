class Webhooks::AppleMessagesForBusinessController < ActionController::API
  before_action :skip_parameter_parsing
  before_action :log_incoming_request
  before_action :find_channel
  before_action :verify_jwt_token
  before_action :decompress_payload

  def process_payload
    Rails.logger.info "[AMB Webhook] Processing payload for channel #{@channel.id}, MSP ID: #{@channel.msp_id}"
    Rails.logger.info "[AMB Webhook] Payload type: #{@decompressed_payload['type']}, ID: #{@decompressed_payload['id']}"

    # Check if message contains IDR (Interactive Data Reference)
    # IDR URLs expire very quickly, so we must process synchronously
    has_idr = @decompressed_payload.dig('interactiveDataRef').present?

    if has_idr
      Rails.logger.info '[AMB Webhook] IDR detected - processing synchronously to prevent expiration'
      Webhooks::AppleMessagesForBusinessEventsJob.perform_now(
        @channel.id,
        @decompressed_payload,
        extract_headers
      )
      Rails.logger.info '[AMB Webhook] IDR processed synchronously'
    else
      Webhooks::AppleMessagesForBusinessEventsJob.perform_later(
        @channel.id,
        @decompressed_payload,
        extract_headers
      )
      Rails.logger.info '[AMB Webhook] Job enqueued successfully'
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error "[AMB Webhook] Processing failed: #{e.message}"
    Rails.logger.error "[AMB Webhook] Backtrace: #{e.backtrace.join("\n")}"
    head :bad_request
  end

  private

  def log_incoming_request
    Rails.logger.info "[AMB Webhook] Incoming request to #{request.path}"
    Rails.logger.info "[AMB Webhook] Method: #{request.method}"
    Rails.logger.info "[AMB Webhook] Headers: #{request.headers.to_h.select { |k, _| k.match?(/source|destination|authorization|content/i) }}"
    Rails.logger.info "[AMB Webhook] Content-Type: #{request.content_type}"
    Rails.logger.info "[AMB Webhook] Content-Length: #{request.content_length}"
    Rails.logger.info "[AMB Webhook] User-Agent: #{request.headers['User-Agent']}"
    Rails.logger.info "[AMB Webhook] X-Forwarded-For: #{request.headers['X-Forwarded-For']}"
  end

  def skip_parameter_parsing
    # Skip automatic parameter parsing for gzipped payloads
    request.body.rewind if request.body.respond_to?(:rewind)
  end

  def find_channel
    # Extract business_id from the destination-id header sent by Apple
    business_id = request.headers['destination-id']

    unless business_id.present?
      Rails.logger.error '[AMB Webhook] Missing destination-id header'
      Rails.logger.info "[AMB Webhook] Available headers: #{request.headers.to_h.select { |k, _| k.match?(/id/i) }}"
      head :bad_request
      return
    end

    Rails.logger.info "[AMB Webhook] Looking for channel with Business ID: #{business_id}"

    @channel = Channel::AppleMessagesForBusiness.find_by(business_id: business_id)

    unless @channel
      Rails.logger.error "[AMB Webhook] Channel not found for Business ID: #{business_id}"
      Rails.logger.info "[AMB Webhook] Available channels: #{Channel::AppleMessagesForBusiness.pluck(:business_id).join(', ')}"
      head :not_found
      return
    end

    Rails.logger.info "[AMB Webhook] Found channel #{@channel.id} (MSP ID: #{@channel.msp_id}) for Business ID: #{business_id}"
  end

  def verify_jwt_token
    auth_header = request.headers['Authorization']
    unless auth_header&.start_with?('Bearer ')
      Rails.logger.error "[AMB Webhook] Missing or invalid Authorization header: #{auth_header}"
      head :unauthorized
      return
    end

    token = auth_header.sub('Bearer ', '')
    Rails.logger.info "[AMB Webhook] Verifying JWT token for MSP ID: #{@channel.msp_id}"
    Rails.logger.info "[AMB Webhook] Token length: #{token.length}, Token preview: #{token[0..20]}..."

    @channel.verify_jwt_token(token)
    Rails.logger.info '[AMB Webhook] JWT verification successful'
  rescue JWT::DecodeError => e
    Rails.logger.error "[AMB Webhook] JWT verification failed for MSP ID: #{@channel.msp_id}: #{e.message}"
    Rails.logger.error "[AMB Webhook] Full token: #{token}"
    head :forbidden
  end

  def decompress_payload
    raw_data = request.body.read
    Rails.logger.info "[AMB Webhook] Payload size: #{raw_data.size} bytes"

    if raw_data.empty?
      Rails.logger.warn '[AMB Webhook] Empty payload received'
      @decompressed_payload = {}
      return
    end

    begin
      @decompressed_payload = if gzipped?
                                decompress_gzip(raw_data)
                              else
                                JSON.parse(raw_data)
                              end

      Rails.logger.info '[AMB Webhook] Payload processed successfully'
      Rails.logger.info "[AMB Webhook] Payload keys: #{@decompressed_payload.keys.join(', ')}"
    rescue StandardError => e
      Rails.logger.error "[AMB Webhook] Payload processing failed: #{e.message}"
      Rails.logger.error "[AMB Webhook] Raw payload (first 100 bytes): #{raw_data[0..99].inspect}"
      head :bad_request
    end
  end

  def gzipped?
    request.headers['Content-Encoding']&.downcase == 'gzip'
  end

  def decompress_gzip(data)
    gz = Zlib::GzipReader.new(StringIO.new(data))
    JSON.parse(gz.read)
  ensure
    gz&.close
  end

  def extract_headers
    {
      source_id: request.headers['source-id'],
      destination_id: request.headers['destination-id'],
      capability_list: request.headers['capability-list']
    }
  end
end
