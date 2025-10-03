# == Schema Information
#
# Table name: attachments
#
#  id                   :integer          not null, primary key
#  coordinates_lat      :float            default(0.0)
#  coordinates_long     :float            default(0.0)
#  encrypted            :boolean          default(FALSE)
#  encryption_algorithm :string
#  encryption_key       :text
#  extension            :string
#  external_url         :string
#  fallback_title       :string
#  file_hash_value      :string
#  file_type            :integer          default("image")
#  meta                 :jsonb
#  storage_key_value    :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :integer          not null
#  message_id           :integer          not null
#
# Indexes
#
#  index_attachments_on_account_id         (account_id)
#  index_attachments_on_encrypted          (encrypted)
#  index_attachments_on_file_hash_value    (file_hash_value)
#  index_attachments_on_message_id         (message_id)
#  index_attachments_on_storage_key_value  (storage_key_value) UNIQUE
#

class Attachment < ApplicationRecord
  include Rails.application.routes.url_helpers

  ACCEPTABLE_FILE_TYPES = %w[
    text/csv text/plain text/rtf
    application/json application/pdf
    application/zip application/x-7z-compressed application/vnd.rar application/x-tar
    application/msword application/vnd.ms-excel application/vnd.ms-powerpoint application/rtf
    application/vnd.oasis.opendocument.text
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    model/vnd.usdz+zip
    application/vnd.usdz+zip
  ].freeze
  belongs_to :account
  belongs_to :message
  has_one_attached :file
  validate :acceptable_file
  validates :external_url, length: { maximum: Limits::URL_LENGTH_LIMIT }
  enum file_type: { :image => 0, :audio => 1, :video => 2, :file => 3, :location => 4, :fallback => 5, :share => 6, :story_mention => 7,
                    :contact => 8, :ig_reel => 9 }

  # Encryption support for Apple Messages for Business
  def encrypted?
    return false unless self.respond_to?(:encryption_key) && self.respond_to?(:encrypted)
    encrypted == true && encryption_key.present?
  end

  def file_hash
    return nil unless self.respond_to?(:file_hash_value)
    file_hash_value
  end

  def storage_key
    return nil unless self.respond_to?(:storage_key_value)
    storage_key_value
  end

  def push_event_data
    return unless file_type

    base_data.merge(metadata_for_file_type)
  end

  # NOTE: the URl returned does a 301 redirect to the actual file
  def file_url
    return '' unless file.attached?
    
    Rails.logger.info "[Attachment] Generating file_url for attachment ID: #{id}"
    
    # Use custom controller for Apple Messages for Business attachments
    if message&.inbox&.channel_type == 'Channel::AppleMessagesForBusiness'
      Rails.logger.info "[Attachment] AMB channel detected. Using custom URL generator with domain."
      token = generate_attachment_token(id)
      url = with_custom_host { Rails.application.routes.url_helpers.apple_messages_for_business_attachment_url(id, token: token) }
      Rails.logger.info "[Attachment] Generated AMB custom domain URL: #{url}"
      url
    else
      Rails.logger.info "[Attachment] Using standard url_for helper."
      url = url_for(file)
      Rails.logger.info "[Attachment] Generated standard URL: #{url}"
      url
    end
  end

  # NOTE: for External services use this methods since redirect doesn't work effectively in a lot of cases
  def download_url
    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    file.attached? ? file.blob.url : ''
  end

  def thumb_url
    return '' unless file.attached? && image?

    Rails.logger.info "[Attachment] Generating thumb_url for attachment ID: #{id}"
    begin
      # Use custom controller for Apple Messages for Business attachments
      if message&.inbox&.channel_type == 'Channel::AppleMessagesForBusiness'
        Rails.logger.info "[Attachment] AMB channel detected for thumb. Using custom URL generator with domain."
        token = generate_attachment_token(id)
        url = with_custom_host { Rails.application.routes.url_helpers.apple_messages_for_business_attachment_url(id, token: token) }
        Rails.logger.info "[Attachment] Generated AMB custom domain thumb URL: #{url}"
        url
      else
        Rails.logger.info "[Attachment] Using standard url_for helper for thumb."
        url = url_for(file.representation(resize_to_fill: [250, nil]))
        Rails.logger.info "[Attachment] Generated standard thumb URL: #{url}"
        url
      end
    rescue ActiveStorage::UnrepresentableError => e
      Rails.logger.warn "[Attachment] Unrepresentable image attachment: #{id} (#{file.filename}) - #{e.message}"
      ''
    end
  end

  private

  def with_custom_host
    original_host = Rails.application.routes.default_url_options[:host]
    original_protocol = Rails.application.routes.default_url_options[:protocol]
    
    Rails.logger.info "[Attachment] Entering with_custom_host block. Original host: #{original_host}"
    # Use environment variable, or check for active dev server URL, or fallback to localhost
    custom_host = ENV['FRONTEND_URL'] || detect_active_public_url || 'localhost:10750'
    Rails.logger.info "[Attachment] Using custom host: #{custom_host}. Setting it for URL generation."
    Rails.application.routes.default_url_options[:host] = custom_host
    Rails.application.routes.default_url_options[:protocol] = 'https'
    
    result = yield
    
    Rails.logger.info "[Attachment] Restoring original host: #{original_host}"
    Rails.application.routes.default_url_options[:host] = original_host
    Rails.application.routes.default_url_options[:protocol] = original_protocol
    
    result
  end

  def ngrok_available?
    require 'net/http'
    require 'json'
    
    begin
      # Try to connect to ngrok's local API
      uri = URI('http://localhost:4040/api/tunnels')
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        tunnels = JSON.parse(response.body)['tunnels']
        
        # Check if there's an HTTPS tunnel pointing to port 3000
        tunnel = tunnels.find do |t|
          t['config']['addr'] == 'http://localhost:3000' && t['public_url'].start_with?('https://')
        end
        
        return !tunnel.nil?
      end
    rescue => e
      Rails.logger.debug "[Apple Messages for Business] Could not detect ngrok: #{e.message}"
    end
    
    false
  end

  def detect_current_ngrok_host
    require 'net/http'
    require 'json'
    
    begin
      # Try to connect to ngrok's local API
      uri = URI('http://localhost:4040/api/tunnels')
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        tunnels = JSON.parse(response.body)['tunnels']
        
        # Find the HTTPS tunnel pointing to port 3000
        tunnel = tunnels.find do |t|
          t['config']['addr'] == 'http://localhost:3000' && t['public_url'].start_with?('https://')
        end
        
        if tunnel
          # Extract just the host from the full URL
          return URI.parse(tunnel['public_url']).host
        end
      end
    rescue => e
      Rails.logger.debug "[Apple Messages for Business] Could not detect ngrok host: #{e.message}"
    end
    
    # Fallback to localhost if ngrok is not available
    'localhost:3000'
  end

  def generate_attachment_token(attachment_id)
    # Generate a simple token based on attachment ID and a secret
    secret = Rails.application.secret_key_base
    Digest::SHA256.hexdigest("#{attachment_id}-#{secret}")[0..15]
  end

  def with_attached_file?
    [:image, :audio, :video, :file].include?(file_type.to_sym)
  end

  private

  def metadata_for_file_type
    case file_type.to_sym
    when :location
      location_metadata
    when :fallback
      fallback_data
    when :contact
      contact_metadata
    when :audio
      audio_metadata
    else
      file_metadata
    end
  end

  def audio_metadata
    audio_file_data = base_data.merge(file_metadata)
    audio_file_data.merge(
      {
        transcribed_text: meta&.[]('transcribed_text') || ''
      }
    )
  end

  def file_metadata
    metadata = {
      extension: extension,
      data_url: file_url,
      thumb_url: thumb_url,
      file_size: file.byte_size,
      width: file.metadata[:width],
      height: file.metadata[:height]
    }

    metadata[:data_url] = metadata[:thumb_url] = external_url if message.inbox.instagram? && message.incoming?
    metadata
  end

  def location_metadata
    {
      coordinates_lat: coordinates_lat,
      coordinates_long: coordinates_long,
      fallback_title: fallback_title,
      data_url: external_url
    }
  end

  def fallback_data
    {
      fallback_title: fallback_title,
      data_url: external_url
    }
  end

  def base_data
    {
      id: id,
      message_id: message_id,
      file_type: file_type,
      account_id: account_id
    }
  end

  def contact_metadata
    {
      fallback_title: fallback_title,
      meta: meta || {}
    }
  end

  def should_validate_file?
    return unless file.attached?
    # we are only limiting attachment types in case of website widget
    return unless message.inbox.channel_type == 'Channel::WebWidget'

    true
  end

  def acceptable_file
    return unless should_validate_file?

    validate_file_size(file.byte_size)
    validate_file_content_type(file.content_type)
  end

  def validate_file_content_type(file_content_type)
    # Check if it's a USDZ file by extension (fallback for incorrect MIME types)
    is_usdz = file.filename.to_s.downcase.end_with?('.usdz')

    errors.add(:file, 'type not supported') unless media_file?(file_content_type) || ACCEPTABLE_FILE_TYPES.include?(file_content_type) || is_usdz
  end

  def validate_file_size(byte_size)
    errors.add(:file, 'size is too big') if byte_size > 40.megabytes
  end

  def media_file?(file_content_type)
    file_content_type.start_with?('image/', 'video/', 'audio/')
  end

  private

  # Detect the active public URL by checking what the dev server is using
  def detect_active_public_url
    begin
      # Check if Tailscale URL is saved (from dev-server.sh)
      tailscale_url_file = Rails.root.join('tmp', 'pids', 'tailscale_url.txt')
      if File.exist?(tailscale_url_file)
        tailscale_url = File.read(tailscale_url_file).strip
        return tailscale_url if tailscale_url.present?
      end

      # Check if ngrok is running by trying to fetch tunnel info
      require 'net/http'
      uri = URI('http://localhost:4040/api/tunnels')
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        require 'json'
        tunnels = JSON.parse(response.body)
        public_url = tunnels.dig('tunnels', 0, 'public_url')
        return public_url.sub(/^https?:\/\//, '') if public_url&.include?('https')
      end
    rescue => e
      Rails.logger.debug "[Attachment] Could not detect active public URL: #{e.message}"
    end

    # Check if custom domain mode is being used (nginx running on port 443)
    begin
      require 'socket'
      TCPSocket.new('localhost', 443).close
      return 'dev.rhaps.net'  # Custom domain is available
    rescue Errno::ECONNREFUSED
      # Custom domain not available
    end

    nil
  end
end

Attachment.include_mod_with('Concerns::Attachment')
