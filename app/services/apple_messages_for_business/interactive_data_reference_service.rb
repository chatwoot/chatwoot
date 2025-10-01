class AppleMessagesForBusiness::InteractiveDataReferenceService
  include ::FileTypeHelper

  def initialize(idr_data:, channel:)
    @idr_data = idr_data
    @channel = channel
  end

  def retrieve_and_decrypt
    Rails.logger.info '[AMB IDR] Starting Interactive Data Reference processing'
    Rails.logger.info "[AMB IDR] IDR Data: #{@idr_data.inspect}"

    validate_idr_data!

    # Step 1: Download the encrypted JSON from the IDR URL
    encrypted_data = download_encrypted_data

    # Step 2: Decrypt the data using the provided signature
    decrypted_json = decrypt_data(encrypted_data)

    # Step 3: Parse the decrypted JSON
    interactive_data = JSON.parse(decrypted_json)

    Rails.logger.info '[AMB IDR] Successfully processed Interactive Data Reference'
    Rails.logger.info "[AMB IDR] Decrypted data keys: #{interactive_data.keys.inspect}"

    interactive_data
  rescue StandardError => e
    Rails.logger.error "[AMB IDR] Failed to process Interactive Data Reference: #{e.message}"
    Rails.logger.error "[AMB IDR] Backtrace: #{e.backtrace.join("\n")}"
    raise e
  end

  private

  def validate_idr_data!
    required_fields = %w[bid owner url size signature dataRefSig]
    missing_fields = required_fields.reject { |field| @idr_data[field].present? }

    if missing_fields.any?
      raise ArgumentError, "Missing required IDR fields: #{missing_fields.join(', ')}"
    end

    Rails.logger.info '[AMB IDR] IDR data validation passed'
  end

  def download_encrypted_data
    Rails.logger.info "[AMB IDR] Downloading encrypted data from: #{@idr_data['url']}"

    # Prepare headers for the download request
    headers = {
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'source-id' => @channel.business_id,
      'owner' => @idr_data['owner'],
      'signature' => @idr_data['signature'],
      'url' => @idr_data['url']
    }

    Rails.logger.info "[AMB IDR] Download headers: #{headers.except('Authorization').inspect}"

    # Download the encrypted data
    response = HTTParty.get(
      @idr_data['url'],
      headers: headers,
      timeout: 30,
      stream_body: true
    )

    unless response.success?
      raise "IDR download failed: #{response.code} #{response.message}"
    end

    encrypted_data = response.body
    Rails.logger.info "[AMB IDR] Downloaded #{encrypted_data.bytesize} bytes of encrypted data"

    # Verify the size matches the expected size
    expected_size = @idr_data['size'].to_i
    if encrypted_data.bytesize != expected_size
      Rails.logger.warn "[AMB IDR] Size mismatch: expected #{expected_size}, got #{encrypted_data.bytesize}"
    end

    encrypted_data
  end

  def decrypt_data(encrypted_data)
    Rails.logger.info '[AMB IDR] Decrypting Interactive Data Reference'

    # The dataRefSig is the decryption key for the IDR
    decryption_key = @idr_data['dataRefSig']

    unless decryption_key.present?
      raise 'Missing dataRefSig for IDR decryption'
    end

    # Use the existing attachment cipher service for decryption
    # The IDR uses the same AES-256-CTR encryption as attachments
    decrypted_data = AppleMessagesForBusiness::AttachmentCipherService.decrypt(
      encrypted_data,
      decryption_key
    )

    Rails.logger.info "[AMB IDR] Decrypted #{decrypted_data.bytesize} bytes of JSON data"

    # The decrypted data should be valid JSON
    begin
      JSON.parse(decrypted_data)
      Rails.logger.info '[AMB IDR] Decrypted data is valid JSON'
    rescue JSON::ParserError => e
      Rails.logger.error "[AMB IDR] Decrypted data is not valid JSON: #{e.message}"
      raise "IDR decryption produced invalid JSON: #{e.message}"
    end

    decrypted_data
  end

  def self.process_idr_response(idr_data, channel)
    service = new(idr_data: idr_data, channel: channel)
    service.retrieve_and_decrypt
  end
end