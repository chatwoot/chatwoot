# frozen_string_literal: true

require 'base64'

class AppleMessagesForBusiness::SendRichLinkService
  AMB_SERVER = 'https://mspgw.push.apple.com/v1'

  def initialize(channel:, destination_id:, message:)
    @channel = channel
    @destination_id = destination_id
    @message = message
  end

  def perform
    message_id = SecureRandom.uuid

    rich_link_data = build_rich_link_data

    payload = {
      id: message_id,
      type: 'richLink',
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      v: 1,
      body: rich_link_data[:url],
      richLinkData: rich_link_data
    }

    Rails.logger.info "🔍 Rich Link - Final payload richLinkData: #{rich_link_data.to_json}"
    Rails.logger.info "🔍 Rich Link - Has image asset: #{rich_link_data[:assets]&.key?(:image)}"
    if rich_link_data[:assets]&.key?(:image)
      Rails.logger.info "🔍 Rich Link - Image data length: #{rich_link_data[:assets][:image][:data]&.length}"
      Rails.logger.info "🔍 Rich Link - Image mime type: #{rich_link_data[:assets][:image][:mimeType]}"
    end

    response = send_to_apple_gateway(payload, message_id)

    if response.success?
      { success: true, message_id: message_id }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  rescue StandardError => e
    Rails.logger.error "Rich link send failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def build_rich_link_data
    content_attrs = @message.content_attributes

    {
      url: content_attrs['url'] || @message.content,
      title: content_attrs['title'] || extract_title_from_url(content_attrs['url']),
      assets: build_assets(content_attrs)
    }
  end

  def build_assets(content_attrs)
    assets = {}

    # Get image from either 'image_data' (base64), 'image_url' (URL), or 'favicon_url' (fallback)
    image_source = content_attrs['image_data'] || content_attrs['image_url'] || content_attrs['favicon_url']

    Rails.logger.info "🔍 Rich Link - Image source: #{image_source&.truncate(100)}"
    Rails.logger.info "🔍 Rich Link - Content attrs keys: #{content_attrs.keys}"

    # Add image asset if provided
    if image_source.present?
      if image_source.start_with?('http')
        # Download and encode image from URL (including favicon URLs)
        Rails.logger.info "🔍 Rich Link - Downloading image from URL: #{image_source}"
        encoded_image = download_and_encode_image(image_source)
        if encoded_image
          Rails.logger.info "✅ Rich Link - Successfully encoded image (#{encoded_image.length} chars)"
          assets[:image] = {
            data: encoded_image,
            mimeType: detect_image_mime_type(image_source, content_attrs)
          }
        else
          Rails.logger.error "❌ Rich Link - Failed to download/encode image from URL: #{image_source}"
        end
      elsif image_source.start_with?('data:image')
        # Handle data URLs (base64 embedded)
        base64_data = image_source.split(',')[1]
        mime_type = image_source.match(/data:([^;]+)/)[1] rescue 'image/jpeg'
        
        assets[:image] = {
          data: base64_data,
          mimeType: mime_type
        }
      else
        # Assume it's already base64 encoded
        assets[:image] = {
          data: image_source,
          mimeType: content_attrs['image_mime_type'] || 'image/jpeg'
        }
      end
    end

    # Add video asset if provided
    if content_attrs['video_url'].present?
      assets[:video] = {
        url: content_attrs['video_url'],
        mimeType: content_attrs['video_mime_type'] || 'video/mp4'
      }
    end

    assets
  end

  def detect_image_mime_type(image_url, content_attrs)
    # Use provided mime type if available
    return content_attrs['image_mime_type'] if content_attrs['image_mime_type'].present?
    
    # Detect from URL extension or source
    case image_url
    when /\.png$/i
      'image/png'
    when /\.gif$/i
      'image/gif'  
    when /\.webp$/i
      'image/webp'
    when /\.svg$/i
      'image/svg+xml'
    when /favicon\.ico$/i
      'image/x-icon'
    else
      'image/jpeg'
    end
  end

  def download_and_encode_image(image_url)
    return nil unless image_url.present?

    Rails.logger.info "🔍 Rich Link - Starting download for: #{image_url}"

    # Enhanced headers for better favicon access
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
      'Accept' => 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'Accept-Language' => 'en-US,en;q=0.9',
      'Cache-Control' => 'no-cache'
    }

    # Download image with timeout and size limits
    response = HTTParty.get(
      image_url,
      timeout: 15,  # Increased timeout for favicons
      headers: headers,
      follow_redirects: true
    )

    Rails.logger.info "🔍 Rich Link - Response code: #{response.code}"
    Rails.logger.info "🔍 Rich Link - Content-Type: #{response.headers['content-type']}"
    Rails.logger.info "🔍 Rich Link - Body size: #{response.body.bytesize} bytes"

    unless response.success?
      Rails.logger.error "❌ Rich Link - HTTP request failed with code: #{response.code}"
      return nil
    end

    # Check file size (limit to 1MB for Rich Links)
    if response.body.bytesize > 1.megabyte
      Rails.logger.error "❌ Rich Link - Image too large: #{response.body.bytesize} bytes (max 1MB)"
      return nil
    end

    # Validate content type
    content_type = response.headers['content-type']
    unless content_type&.start_with?('image/')
      Rails.logger.error "❌ Rich Link - Invalid content type: #{content_type}"
      return nil
    end

    # Encode to base64
    encoded = Base64.strict_encode64(response.body)
    Rails.logger.info "✅ Rich Link - Successfully encoded image (#{encoded.length} chars)"
    encoded
  rescue StandardError => e
    Rails.logger.error "❌ Rich Link - Failed to download image #{image_url}: #{e.message}"
    Rails.logger.error "❌ Rich Link - Backtrace: #{e.backtrace.first(3).join("\n")}"
    nil
  end

  def extract_title_from_url(url)
    return 'Rich Link' unless url.present?

    # Try to extract domain name as fallback title
    uri = URI.parse(url)
    uri.host&.gsub('www.', '')&.capitalize || 'Rich Link'
  rescue URI::InvalidURIError
    'Rich Link'
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    HTTParty.post(
      "#{AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 30
    )
  end
end
