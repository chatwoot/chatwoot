module ProductCatalogs
  class S3StreamingUploaderService
    require 'net/http'
    require 'uri'
    BUFFER_SIZE = 5 * 1024 * 1024 # 5MB minimum for S3 multipart
    DOWNLOAD_TIMEOUT = 300 # 5 minutes

    # WhatsApp size limits
    SIZE_LIMITS = {
      'IMAGE' => 5 * 1024 * 1024,      # 5 MB
      'VIDEO' => 16 * 1024 * 1024,     # 16 MB
      'DOCUMENT' => 100 * 1024 * 1024, # 100 MB
      'AUDIO' => 16 * 1024 * 1024      # 16 MB
    }.freeze

    # Valid extensions for WhatsApp
    VALID_EXTENSIONS = {
      'IMAGE' => %w[.jpeg .jpg .png],
      'VIDEO' => %w[.mp4],
      'DOCUMENT' => %w[.txt .xls .xlsx .doc .docx .ppt .pptx .pdf],
      'AUDIO' => %w[.mp3 .ogg]
    }.freeze

    Result = Struct.new(:success, :s3_key, :error, :retriable, :file_size, :mime_type, keyword_init: true)

    def initialize(url:, s3_key:, file_type:, bucket: nil)
      @url = url
      @s3_key = s3_key
      @file_type = file_type.to_s.upcase
      @bucket = bucket || ENV.fetch('S3_BUCKET_NAME', '')
      @s3_client = Aws::S3::Client.new
    end

    def upload
      normalized_url = normalize_url(@url)

      # Validate extension before starting (not retriable)
      extension_error = validate_extension
      return Result.new(success: false, error: extension_error, retriable: false) if extension_error

      upload_id = nil
      parts = []
      part_number = 1
      buffer = String.new(encoding: 'BINARY')
      total_bytes = 0
      detected_content_type = detect_content_type

      begin
        # Initialize multipart upload
        multipart = @s3_client.create_multipart_upload(
          bucket: @bucket,
          key: @s3_key,
          content_type: detected_content_type
        )
        upload_id = multipart.upload_id

        # Stream download and upload
        stream_download(normalized_url) do |chunk|
          buffer << chunk
          total_bytes += chunk.bytesize

          # Validate size (not retriable if exceeded)
          size_error = validate_size(total_bytes)
          raise SizeLimitExceeded, size_error if size_error

          # Upload part when buffer reaches minimum size
          while buffer.bytesize >= BUFFER_SIZE
            part_data = buffer.slice!(0, BUFFER_SIZE)
            part = upload_part(upload_id, part_number, part_data)
            parts << { etag: part.etag, part_number: part_number }
            part_number += 1
          end
        end

        # Upload remaining buffer as final part
        if buffer.bytesize.positive?
          part = upload_part(upload_id, part_number, buffer)
          parts << { etag: part.etag, part_number: part_number }
        end

        # Complete multipart upload
        @s3_client.complete_multipart_upload(
          bucket: @bucket,
          key: @s3_key,
          upload_id: upload_id,
          multipart_upload: { parts: parts }
        )

        Result.new(
          success: true,
          s3_key: @s3_key,
          retriable: false,
          file_size: total_bytes,
          mime_type: detected_content_type
        )
      rescue SizeLimitExceeded, ContentLengthMissing => e
        abort_multipart_upload(upload_id) if upload_id
        Result.new(success: false, error: e.message, retriable: false)
      rescue StandardError => e
        # Abort multipart upload on failure (retriable for network/S3 errors)
        abort_multipart_upload(upload_id) if upload_id
        Result.new(success: false, error: e.message, retriable: true)
      end
    end

    class SizeLimitExceeded < StandardError; end
    class ContentLengthMissing < StandardError; end

    private

    def normalize_url(url)
      return url if url.blank?

      uri = URI.parse(url)

      # Handle Dropbox URLs
      if uri.host&.include?('dropbox.com')
        return normalize_dropbox_url(url, uri)
      end

      url
    end

    def normalize_dropbox_url(url, uri)
      # Ensure dl=1 parameter for direct download
      query_params = URI.decode_www_form(uri.query || '').to_h
      query_params['dl'] = '1'

      uri.query = URI.encode_www_form(query_params)
      uri.to_s
    end

    def stream_download(url)
      uri = URI.parse(url)
      max_redirects = 5
      redirect_count = 0

      loop do
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.read_timeout = DOWNLOAD_TIMEOUT
        http.open_timeout = 30

        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = 'Mozilla/5.0 (compatible; ProductCatalogBot/1.0)'

        http.request(request) do |response|
          case response
          when Net::HTTPSuccess
            validate_content_length!(response)

            response.read_body do |chunk|
              yield chunk
            end
            return
          when Net::HTTPRedirection
            redirect_count += 1
            raise 'Too many redirects' if redirect_count > max_redirects

            location = response['location']
            uri = URI.parse(location)
            uri = URI.join("#{uri.scheme}://#{uri.host}", location) unless uri.host
          else
            raise "HTTP error: #{response.code} #{response.message}"
          end
        end
      end
    end

    def validate_content_length!(response)
      content_length = response['content-length']

      raise ContentLengthMissing, 'Content-Length header is missing' if content_length.blank?

      max_size = SIZE_LIMITS[@file_type]
      raise SizeLimitExceeded, "File type '#{@file_type}' is not supported" if max_size.nil?

      file_size = content_length.to_i
      return if file_size <= max_size

      max_mb = (max_size / (1024.0 * 1024)).round(1)
      file_mb = (file_size / (1024.0 * 1024)).round(2)
      raise SizeLimitExceeded, "File size #{file_mb}MB exceeds maximum of #{max_mb}MB for #{@file_type}"
    end

    def upload_part(upload_id, part_number, data)
      @s3_client.upload_part(
        bucket: @bucket,
        key: @s3_key,
        upload_id: upload_id,
        part_number: part_number,
        body: data
      )
    end

    def abort_multipart_upload(upload_id)
      @s3_client.abort_multipart_upload(
        bucket: @bucket,
        key: @s3_key,
        upload_id: upload_id
      )
    rescue StandardError => e
      Rails.logger.error("Failed to abort multipart upload: #{e.message}")
    end

    def validate_extension
      valid_extensions = VALID_EXTENSIONS[@file_type]

      return "File type '#{@file_type}' is not supported" if valid_extensions.nil?

      extension = File.extname(@s3_key).downcase
      return nil if valid_extensions.include?(extension)

      "Extension '#{extension}' not allowed for #{@file_type}. Valid: #{valid_extensions.join(', ')}"
    end

    def validate_size(total_bytes)
      max_size = SIZE_LIMITS[@file_type]

      return "File type '#{@file_type}' is not supported" if max_size.nil?
      return nil unless total_bytes > max_size

      max_mb = (max_size / (1024.0 * 1024)).round(1)
      "File exceeds maximum size of #{max_mb}MB for #{@file_type}"
    end

    def detect_content_type
      extension = File.extname(@s3_key).downcase

      content_types = {
        '.jpg' => 'image/jpeg',
        '.jpeg' => 'image/jpeg',
        '.png' => 'image/png',
        '.gif' => 'image/gif',
        '.webp' => 'image/webp',
        '.mp4' => 'video/mp4',
        '.pdf' => 'application/pdf',
        '.doc' => 'application/msword',
        '.docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        '.xls' => 'application/vnd.ms-excel',
        '.xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '.ppt' => 'application/vnd.ms-powerpoint',
        '.pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        '.txt' => 'text/plain',
        '.mp3' => 'audio/mpeg',
        '.ogg' => 'audio/ogg'
      }

      content_types[extension] || 'application/octet-stream'
    end
  end
end
