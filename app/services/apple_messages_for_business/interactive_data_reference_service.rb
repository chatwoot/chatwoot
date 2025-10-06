class AppleMessagesForBusiness::InteractiveDataReferenceService
  include ::FileTypeHelper

  MSP_GATEWAY_URL = 'https://mspgw.push.apple.com/v1'.freeze

  def initialize(idr_data:, channel:)
    @idr_data = idr_data
    @channel = channel
  end

  def retrieve_and_decrypt
    Rails.logger.info '[AMB IDR] Starting Interactive Data Reference processing'
    Rails.logger.info "[AMB IDR] IDR Data: #{@idr_data.inspect}"

    validate_idr_data!

    # Step 1: Download the encrypted data from the IDR URL
    encrypted_data = download_encrypted_data

    # Step 2: Decrypt and decode the data using Apple's /decodePayload endpoint
    interactive_data = decrypt_data(encrypted_data)

    Rails.logger.info '[AMB IDR] Successfully processed Interactive Data Reference'
    Rails.logger.info "[AMB IDR] Final data keys: #{interactive_data.keys.inspect}"

    interactive_data
  rescue StandardError => e
    Rails.logger.error "[AMB IDR] Failed to process Interactive Data Reference: #{e.message}"
    Rails.logger.error "[AMB IDR] Backtrace: #{e.backtrace.join("\n")}"
    raise e
  end

  private

  def validate_idr_data!
    required_fields = %w[bid owner url size signature]
    missing_fields = required_fields.reject { |field| @idr_data[field].present? }

    raise ArgumentError, "Missing required IDR fields: #{missing_fields.join(', ')}" if missing_fields.any?

    # Check for decryption key (either 'key' or 'dataRefSig')
    unless @idr_data['key'].present? || @idr_data['dataRefSig'].present?
      raise ArgumentError, 'Missing decryption key: neither "key" nor "dataRefSig" found'
    end

    Rails.logger.info '[AMB IDR] IDR data validation passed'
  end

  def download_encrypted_data
    Rails.logger.info '[AMB IDR] Starting IDR download process'
    Rails.logger.info "[AMB IDR] Original iCloud URL: #{@idr_data['url']}"

    # Step 1: Call /preDownload to get temporary download URL
    download_url = call_pre_download

    # Step 2: Download from the temporary URL (no special headers needed)
    encrypted_data = download_from_url(download_url)

    # Verify the size matches the expected size
    expected_size = @idr_data['size'].to_i
    if encrypted_data.bytesize != expected_size
      Rails.logger.warn "[AMB IDR] Size mismatch: expected #{expected_size}, got #{encrypted_data.bytesize}"
      # Don't fail on size mismatch, just warn - content might still be valid
    end

    encrypted_data
  end

  def call_pre_download
    Rails.logger.info '[AMB IDR] Calling /preDownload to get temporary URL'

    # Convert hex signature to base64 as required by Apple MSP
    # Python reference: signature = base64.b16decode(hex_encoded_signature)
    #                   base64_encoded_signature = base64.b64encode(signature)
    hex_signature = @idr_data['signature']
    base64_signature = (@idr_data['signature-base64'].presence || Base64.strict_encode64([hex_signature].pack('H*')))

    # Prepare headers for /preDownload request (GET, not POST!)
    # Python reference uses lowercase header names (line 174-179 in reference)
    headers = {
      'authorization' => "Bearer #{@channel.generate_jwt_token}",
      'source-id' => @channel.business_id, # Use business_id for source-id
      'mmcs-url' => @idr_data['url'],
      'mmcs-signature' => base64_signature,
      'mmcs-owner' => @idr_data['owner']
    }

    Rails.logger.info "[AMB IDR] PreDownload request headers: #{headers.except('authorization').inspect}"

    # Use GET, not POST (per Python reference implementation)
    response = HTTParty.get(
      "#{MSP_GATEWAY_URL}/preDownload",
      headers: headers,
      timeout: 30
    )

    unless response.success?
      Rails.logger.error "[AMB IDR] PreDownload failed: #{response.code} #{response.message}"
      Rails.logger.error "[AMB IDR] PreDownload response body: #{response.body}"
      raise "PreDownload failed: #{response.code} #{response.message}"
    end

    # Parse the response to get the download URL
    result = JSON.parse(response.body)
    download_url = result['download-url']

    raise 'PreDownload response missing download-url' unless download_url.present?

    Rails.logger.info "[AMB IDR] Received temporary download URL: #{download_url}"
    download_url
  end

  def download_from_url(url)
    Rails.logger.info '[AMB IDR] Downloading from temporary URL'

    # Simple GET request to the temporary URL (no authentication headers)
    response = HTTParty.get(
      url,
      timeout: 60,
      follow_redirects: true
    )

    unless response.success?
      Rails.logger.error "[AMB IDR] Download failed: #{response.code} #{response.message}"
      raise "Download from temporary URL failed: #{response.code} #{response.message}"
    end

    encrypted_data = response.body
    Rails.logger.info "[AMB IDR] Downloaded #{encrypted_data.bytesize} bytes of encrypted data"

    encrypted_data
  end

  def decrypt_data(encrypted_data)
    Rails.logger.info '[AMB IDR] Decrypting Interactive Data Reference'

    # The decryption key can be in either 'dataRefSig' or 'key' field
    decryption_key = @idr_data['dataRefSig'] || @idr_data['key']

    raise 'Missing decryption key for IDR decryption' unless decryption_key.present?

    Rails.logger.info "[AMB IDR] Using decryption key from field: #{@idr_data['dataRefSig'].present? ? 'dataRefSig' : 'key'}"

    # Use the existing attachment cipher service for decryption
    # The IDR uses the same AES-256-CTR encryption as attachments
    decrypted_data = AppleMessagesForBusiness::AttachmentCipherService.decrypt(
      encrypted_data,
      decryption_key
    )

    Rails.logger.info "[AMB IDR] Decrypted #{decrypted_data.bytesize} bytes of data"

    # Try /decodePayload first (Python reference approach)
    # If it fails with 403, fall back to manual decompression
    begin
      decoded_data = call_decode_payload(decrypted_data)
      Rails.logger.info '[AMB IDR] Successfully decoded via /decodePayload'
      decoded_data
    rescue StandardError => e
      raise e unless e.message.include?('403') || e.message.include?('Forbidden')

      Rails.logger.warn '[AMB IDR] /decodePayload returned 403, falling back to manual decompression'
      manual_decompress_and_parse(decrypted_data)
    end
  end

  def call_decode_payload(decrypted_data)
    Rails.logger.info '[AMB IDR] Calling /decodePayload to parse interactive data'

    # Headers from Python reference (lines 108-114)
    headers = {
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'source-id' => @idr_data['bid'],
      'accept' => '*/*',
      'accept-encoding' => 'gzip, deflate',
      'bid' => @idr_data['bid']
    }

    Rails.logger.info "[AMB IDR] DecodePayload request for bid: #{@idr_data['bid']}"

    response = HTTParty.post(
      "#{MSP_GATEWAY_URL}/decodePayload",
      headers: headers,
      body: decrypted_data,
      timeout: 30
    )

    unless response.success?
      Rails.logger.error "[AMB IDR] DecodePayload failed: #{response.code} #{response.message}"
      Rails.logger.error "[AMB IDR] DecodePayload response body: #{response.body}"
      raise "DecodePayload failed: #{response.code} #{response.message}"
    end

    # Parse the response - it should be JSON
    interactive_data = JSON.parse(response.body)
    Rails.logger.info '[AMB IDR] Successfully decoded interactive data'
    Rails.logger.info "[AMB IDR] Decoded data keys: #{interactive_data.keys.inspect}"

    # Remove image bitmaps to keep payload manageable (per Python reference line 159)
    interactive_data.delete('images') if interactive_data.key?('images')

    interactive_data
  rescue JSON::ParserError => e
    Rails.logger.error "[AMB IDR] Failed to parse decodePayload response as JSON: #{e.message}"
    Rails.logger.error "[AMB IDR] Response body: #{response.body[0..500]}"
    raise "DecodePayload response is not valid JSON: #{e.message}"
  end

  def manual_decompress_and_parse(decrypted_data)
    Rails.logger.info '[AMB IDR] Manually decompressing gzipped data'

    # The decrypted data is gzip compressed, decompress it
    begin
      gz = Zlib::GzipReader.new(StringIO.new(decrypted_data))
      decompressed_data = gz.read
      gz.close
      Rails.logger.info "[AMB IDR] Decompressed #{decompressed_data.bytesize} bytes of data"
    rescue Zlib::GzipFile::Error => e
      Rails.logger.warn "[AMB IDR] Data is not gzipped: #{e.message}, using as-is"
      decompressed_data = decrypted_data
    end

    # The decompressed data should be binary plist or JSON
    begin
      # Check if it's a binary plist (starts with 'bplist')
      if decompressed_data.start_with?('bplist')
        Rails.logger.info '[AMB IDR] Data is binary plist format, converting to JSON using plutil'
        interactive_data = convert_binary_plist_to_hash(decompressed_data)
        Rails.logger.info '[AMB IDR] Successfully parsed binary plist'
      else
        # Try parsing as JSON
        interactive_data = JSON.parse(decompressed_data)
        Rails.logger.info '[AMB IDR] Successfully parsed JSON'
      end

      # Remove image bitmaps to keep payload manageable
      interactive_data.delete('images') if interactive_data.key?('images')

      Rails.logger.info "[AMB IDR] Parsed data keys: #{interactive_data.keys.inspect}"
      interactive_data
    rescue JSON::ParserError => e
      Rails.logger.error "[AMB IDR] Failed to parse as JSON: #{e.message}"
      Rails.logger.error "[AMB IDR] First 100 bytes: #{decompressed_data[0..99].inspect}"
      raise "IDR decryption produced invalid JSON: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "[AMB IDR] Failed to parse data: #{e.message}"
      Rails.logger.error "[AMB IDR] First 100 bytes: #{decompressed_data[0..99].inspect}"
      raise "IDR parsing failed: #{e.message}"
    end
  end

  def convert_binary_plist_to_hash(binary_plist_data)
    # Use macOS plutil to convert binary plist to XML first, then parse
    require 'tempfile'

    Tempfile.create(['idr_plist', '.plist']) do |plist_file|
      plist_file.binmode
      plist_file.write(binary_plist_data)
      plist_file.flush

      # Convert binary plist to XML using plutil (JSON fails with embedded images)
      xml_output = `plutil -convert xml1 -o - #{plist_file.path} 2>&1`

      raise "Failed to convert binary plist: #{xml_output}" unless $?.success?

      # Parse the XML plist manually to extract key fields
      parse_plist_xml(xml_output)
    end
  end

  def parse_plist_xml(xml_string)
    # Simple XML parsing to extract interactive data fields
    # This avoids issues with embedded binary image data
    require 'rexml/document'

    doc = REXML::Document.new(xml_string)
    result = {}

    # Navigate to the main dict element
    dict = doc.elements['plist/dict']
    return {} unless dict

    # Extract key-value pairs
    current_key = nil
    dict.elements.each do |element|
      if element.name == 'key'
        current_key = element.text
      elsif current_key
        value = extract_plist_value(element)
        result[current_key] = value unless current_key == 'images' # Skip images
        current_key = nil
      end
    end

    Rails.logger.info "[AMB IDR] Extracted plist keys: #{result.keys.inspect}"
    result
  end

  def extract_plist_value(element)
    case element.name
    when 'string'
      element.text
    when 'integer'
      element.text.to_i
    when 'real'
      element.text.to_f
    when 'true'
      true
    when 'false'
      false
    when 'dict'
      hash = {}
      current_key = nil
      element.elements.each do |child|
        if child.name == 'key'
          current_key = child.text
        elsif current_key
          hash[current_key] = extract_plist_value(child)
          current_key = nil
        end
      end
      hash
    when 'array'
      element.elements.map { |child| extract_plist_value(child) }
    end
  end

  def self.process_idr_response(idr_data, channel)
    service = new(idr_data: idr_data, channel: channel)
    service.retrieve_and_decrypt
  end
end
