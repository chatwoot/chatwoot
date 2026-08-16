# frozen_string_literal: true

require 'net/http'

module MyinvestChatImport
  class HubspotClient
    class RequestError < StandardError; end

    CONTACT_PROPERTIES = %w[firstname lastname email phone mobilephone createdate lastmodifieddate].freeze
    MAX_PAGES = 1_000
    MAX_ATTEMPTS = 4
    MAX_FILE_BYTES = 1_073_741_824
    MAX_REDIRECTS = 4
    HUBSPOT_FILE_HOST = /\A(?:[a-z0-9-]+\.)*hubspotusercontent(?:-[a-z0-9-]+)?\.(?:com|net)\z/i

    def initialize(access_token:, base_uri: 'https://api.hubapi.com', sleeper: ->(seconds) { sleep(seconds) }, min_interval: 0.1)
      raise ArgumentError, 'HubSpot access token is required' if access_token.to_s.empty?

      @access_token = access_token
      @base_uri = URI(base_uri)
      @sleeper = sleeper
      @min_interval = Float(min_interval)
      @last_request_at = nil
      raise ArgumentError, 'HubSpot endpoint must use HTTPS' unless @base_uri.is_a?(URI::HTTPS)
      raise ArgumentError, 'invalid request interval' if @min_interval.negative?
    end

    def threads(inbox_id)
      [false, true].flat_map do |archived|
        paginate(
          '/conversations/v3/conversations/threads',
          'inboxId' => inbox_id.to_s,
          'archived' => archived.to_s,
          'limit' => '500'
        )
      end
    end

    def messages(thread_id, archived: false)
      id = numeric_id!(thread_id)
      paginate(
        "/conversations/v3/conversations/threads/#{id}/messages",
        'archived' => archived.to_s,
        'limit' => '100'
      )
    end

    def contacts(ids)
      Array(ids).map(&:to_s).uniq.each_slice(100).each_with_object({}) do |slice, result|
        next if slice.empty?

        slice.each { |id| numeric_id!(id) }
        response = request_json(
          Net::HTTP::Post,
          '/crm/v3/objects/contacts/batch/read',
          body: { 'properties' => CONTACT_PROPERTIES, 'inputs' => slice.map { |id| { 'id' => id } } }
        )
        response.fetch('results').each { |contact| result[contact.fetch('id').to_s] = contact }
      end
    end

    def original_content(thread_id, message_id)
      thread = numeric_id!(thread_id)
      message = path_id!(message_id)
      request_json(Net::HTTP::Get, "/conversations/v3/conversations/threads/#{thread}/messages/#{message}/original-content")
    end

    def download_file(file_id, destination)
      id = numeric_id!(file_id)
      metadata = request_json(Net::HTTP::Get, "/files/v3/files/#{id}/signed-url")
      expected_size = Integer(metadata.fetch('size'))
      raise RequestError, 'HubSpot file exceeds archive limit' unless expected_size.between?(0, MAX_FILE_BYTES)

      download = request_binary(URI(metadata.fetch('url')), destination, expected_size: expected_size)
      {
        'filename' => metadata.fetch('name').to_s,
        'content_type' => download.fetch(:content_type),
        'byte_size' => download.fetch(:byte_size)
      }
    rescue ArgumentError, KeyError, URI::InvalidURIError
      raise RequestError, 'HubSpot returned invalid file metadata'
    end

    private

    attr_reader :access_token, :base_uri, :min_interval, :sleeper

    def paginate(path, query)
      rows = []
      after = nil
      MAX_PAGES.times do
        page_query = query.merge('after' => after).reject { |_key, value| value.nil? }
        response = request_json(Net::HTTP::Get, path, query: page_query)
        page_rows = response.fetch('results')
        rows.concat(page_rows)
        return rows if page_rows.empty? || page_rows.length < Integer(query.fetch('limit'))

        next_after = response.dig('paging', 'next', 'after')
        return rows if next_after.nil? || next_after.to_s == after.to_s

        after = next_after
      end
      raise RequestError, 'HubSpot pagination limit exceeded'
    end

    def request_json(request_class, path, query: {}, body: nil)
      uri = base_uri.dup
      uri.path = path
      uri.query = URI.encode_www_form(query) unless query.empty?
      MAX_ATTEMPTS.times do |index|
        begin
          request = request_class.new(uri)
          request['Authorization'] = "Bearer #{access_token}"
          request['Accept'] = 'application/json'
          if body
            request['Content-Type'] = 'application/json'
            request.body = JSON.generate(body)
          end
          throttle!
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
            http.request(request)
          end
          if response.is_a?(Net::HTTPSuccess)
            parsed = JSON.parse(response.body)
            raise RequestError, 'HubSpot response must be an object' unless parsed.is_a?(Hash)

            return parsed
          end

          retryable = response.code.to_i == 429 || response.code.to_i >= 500
          error = request_error(response, path)
          raise error unless retryable
          raise error if index == MAX_ATTEMPTS - 1

          retry_after = response['Retry-After'].to_i
          delay = response.code.to_i == 429 ? [[retry_after, 10].max, 30].min : index + 1
          sleeper.call(delay)
        rescue JSON::ParserError
          raise RequestError, 'HubSpot returned invalid JSON'
        rescue IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
          raise RequestError, 'HubSpot request failed' if index == MAX_ATTEMPTS - 1

          sleeper.call(index + 1)
        end
      end

      raise RequestError, 'HubSpot request failed'
    end

    def request_binary(uri, destination, expected_size:, redirects: 0)
      raise RequestError, 'HubSpot file redirect limit exceeded' if redirects > MAX_REDIRECTS
      validate_file_uri!(uri)
      request = Net::HTTP::Get.new(uri)
      result = nil
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 120) do |http|
        http.request(request) do |response|
          if response.is_a?(Net::HTTPRedirection)
            location = response['Location']
            raise RequestError, 'HubSpot file redirect is missing' if location.to_s.empty?

            return request_binary(URI.join(uri, location), destination, expected_size: expected_size, redirects: redirects + 1)
          end
          raise RequestError, "HubSpot file download failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          content_length = response['Content-Length']&.to_i
          raise RequestError, 'HubSpot file size mismatch' if content_length && content_length != expected_size
          written = 0
          File.open(destination, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
            response.read_body do |chunk|
              written += chunk.bytesize
              raise RequestError, 'HubSpot file exceeds declared size' if written > expected_size || written > MAX_FILE_BYTES

              file.write(chunk)
            end
          end
          raise RequestError, 'HubSpot file size mismatch' unless written == expected_size

          content_type = response['Content-Type'].to_s.split(';', 2).first.to_s.strip.downcase
          content_type = 'application/octet-stream' unless content_type.match?(%r{\A[a-z0-9][a-z0-9.+-]*/[a-z0-9][a-z0-9.+-]*\z}i)
          result = { content_type: content_type, byte_size: written }
        end
      end
      File.chmod(0o600, destination)
      result
    rescue StandardError
      File.delete(destination) if File.file?(destination)
      raise
    end

    def validate_file_uri!(uri)
      valid = uri.is_a?(URI::HTTPS) && uri.host&.match?(HUBSPOT_FILE_HOST) && uri.userinfo.nil?
      raise RequestError, 'HubSpot returned an unsafe file URL' unless valid
    end

    def throttle!
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      if @last_request_at
        remaining = min_interval - (now - @last_request_at)
        sleeper.call(remaining) if remaining.positive?
      end
      @last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def request_error(response, path)
      category = JSON.parse(response.body)['category'].to_s
      suffix = category.empty? ? '' : " (#{category})"
      RequestError.new("HubSpot #{path} failed with HTTP #{response.code}#{suffix}")
    rescue JSON::ParserError
      RequestError.new("HubSpot #{path} failed with HTTP #{response.code}")
    end

    def numeric_id!(value)
      id = value.to_s
      raise ArgumentError, 'HubSpot id must be numeric' unless id.match?(/\A\d+\z/)

      id
    end

    def path_id!(value)
      id = value.to_s
      raise ArgumentError, 'HubSpot path id is invalid' unless id.match?(/\A[A-Za-z0-9._:-]{1,512}\z/)

      id
    end
  end
end
