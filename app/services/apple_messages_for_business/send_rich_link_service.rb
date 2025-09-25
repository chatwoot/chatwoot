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

    # Add image asset if provided
    if image_source.present?
      if image_source.start_with?('http')
        # Download and encode image from URL (including favicon URLs)
        encoded_image = download_and_encode_image(image_source)
        if encoded_image
          assets[:image] = {
            data: encoded_image,
            mimeType: detect_image_mime_type(image_source, content_attrs)
          }
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

    return nil unless response.success?

    # Check file size (limit to 1MB for Rich Links)
    return nil if response.body.bytesize > 1.megabyte

    # Validate content type
    content_type = response.headers['content-type']
    return nil unless content_type&.start_with?('image/')

    # Encode to base64
    Base64.strict_encode64(response.body)
  rescue StandardError => e
    Rails.logger.error "Failed to download image #{image_url}: #{e.message}"
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
