# frozen_string_literal: true

# EvolutionApi::Client
#
# HTTP client for communicating with Evolution API (Baileys).
# Handles instance creation, Chatwoot integration configuration, and connection management.
#
# Usage:
#   client = EvolutionApi::Client.new
#   client.create_instance(instance_name: 'my-instance')
#   client.connect_instance(instance_name: 'my-instance')
#
module EvolutionApi
  class Client
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class ApiError < Error
      attr_reader :status, :response_body

      def initialize(message, status: nil, response_body: nil)
        @status = status
        @response_body = response_body
        super(message)
      end
    end

    def initialize(base_url: nil, api_key: nil)
      @base_url = base_url || evolution_api_url
      @api_key = api_key || evolution_api_key

      validate_configuration!
    end

    # Creates a new Evolution Baileys instance
    # @param instance_name [String] Unique name for the instance
    # @return [Hash] Created instance data
    def create_instance(instance_name:)
      body = {
        instanceName: instance_name,
        integration: 'WHATSAPP-BAILEYS'
      }
      request(:post, '/instance/create', body)
    end

    # Fetches an instance by name
    # @param instance_name [String]
    # @return [Hash] Instance data
    def fetch_instance(instance_name:)
      request(:get, "/instance/fetchInstances?instanceName=#{CGI.escape(instance_name)}")
    end

    # Fetches all instances
    # @return [Array<Hash>] List of all instances
    def fetch_all_instances
      request(:get, '/instance/fetchInstances')
    end

    # Configures Chatwoot integration for an Evolution instance
    # @param instance_name [String]
    # @param chatwoot_config [Hash] Chatwoot integration settings:
    #   { url:, token:, account_id:, sign_msg:, reopen_conversation:, conversation_pending:,
    #     name_inbox:, merge_brazil_contacts:, import_contacts:, import_messages:, days_limit_import_messages:,
    #     auto_create: }
    # @return [Hash] Integration response
    def set_chatwoot_integration(instance_name:, chatwoot_config:)
      body = {
        enabled: true,
        accountId: chatwoot_config[:account_id].to_s,
        token: chatwoot_config[:token],
        url: chatwoot_config[:url],
        signMsg: chatwoot_config.fetch(:sign_msg, true),
        signDelimiter: chatwoot_config.fetch(:sign_delimiter, "\n"),
        reopenConversation: chatwoot_config.fetch(:reopen_conversation, true),
        conversationPending: chatwoot_config.fetch(:conversation_pending, false),
        nameInbox: chatwoot_config[:name_inbox] || instance_name,
        mergeBrazilContacts: chatwoot_config.fetch(:merge_brazil_contacts, true),
        importContacts: chatwoot_config.fetch(:import_contacts, true),
        importMessages: chatwoot_config.fetch(:import_messages, true),
        daysLimitImportMessages: chatwoot_config.fetch(:days_limit_import_messages, 3),
        autoCreate: chatwoot_config.fetch(:auto_create, true)
      }

      request(:post, "/chatwoot/set/#{CGI.escape(instance_name)}", body)
    end

    # Retrieves Chatwoot integration settings for an instance
    # @param instance_name [String]
    # @return [Hash] Current Chatwoot integration settings
    def find_chatwoot_integration(instance_name:)
      request(:get, "/chatwoot/find/#{CGI.escape(instance_name)}")
    end

    # Gets the connection state of an instance
    # @param instance_name [String]
    # @return [Hash] Connection state
    def connection_state(instance_name:)
      request(:get, "/instance/connectionState/#{CGI.escape(instance_name)}")
    end

    # Generates QR code for Baileys instances
    # @param instance_name [String]
    # @return [Hash] QR code data
    def connect_instance(instance_name:)
      request(:get, "/instance/connect/#{CGI.escape(instance_name)}")
    end

    # Restarts an Evolution instance
    # @param instance_name [String]
    # @return [Hash] Restart result
    def restart_instance(instance_name:)
      request(:post, "/instance/restart/#{CGI.escape(instance_name)}")
    end

    # Logs out (disconnects) an instance from WhatsApp
    # @param instance_name [String]
    # @return [Hash] Logout result
    def logout_instance(instance_name:)
      request(:delete, "/instance/logout/#{CGI.escape(instance_name)}")
    end

    # Deletes an Evolution instance
    # @param instance_name [String]
    # @return [Hash] Deletion result
    def delete_instance(instance_name:)
      request(:delete, "/instance/delete/#{CGI.escape(instance_name)}")
    end

    # Fetches instance settings (reject calls, groups ignore, always online, etc.)
    # @param instance_name [String]
    # @return [Hash] Instance settings
    def find_settings(instance_name:)
      request(:get, "/settings/find/#{CGI.escape(instance_name)}")
    end

    # Updates instance settings
    # @param instance_name [String]
    # @param settings [Hash] Settings to update:
    #   { reject_call:, msg_call:, groups_ignore:, always_online:, read_messages:, read_status:, sync_full_history: }
    # @return [Hash] Updated settings
    def set_settings(instance_name:, settings:)
      body = {
        rejectCall: settings[:reject_call],
        msgCall: settings[:msg_call],
        groupsIgnore: settings[:groups_ignore],
        alwaysOnline: settings[:always_online],
        readMessages: settings[:read_messages],
        readStatus: settings[:read_status],
        syncFullHistory: settings[:sync_full_history]
      }.compact

      request(:post, "/settings/set/#{CGI.escape(instance_name)}", body)
    end

    # Sends a text message via Evolution API
    # @param instance_name [String]
    # @param phone_number [String] Recipient phone number (without + prefix)
    # @param text [String] Message text
    # @param options [Hash] Optional params (quoted message, etc.)
    # @return [Hash] Message send result with message ID
    def send_text(instance_name:, phone_number:, text:, options: {})
      body = {
        number: phone_number.to_s.delete('+'),
        text: text
      }
      body[:quoted] = options[:quoted] if options[:quoted].present?

      request(:post, "/message/sendText/#{CGI.escape(instance_name)}", body)
    end

    # Sends a media message via Evolution API
    # @param instance_name [String]
    # @param phone_number [String] Recipient phone number
    # @param media_type [String] 'image', 'video', 'audio', 'document'
    # @param media_url [String] URL to the media file
    # @param options [Hash] Optional params (caption, filename, etc.)
    # @return [Hash] Message send result
    def send_media(instance_name:, phone_number:, media_type:, media_url:, options: {})
      body = {
        number: phone_number.to_s.delete('+'),
        mediatype: media_type,
        media: media_url
      }
      body[:caption] = options[:caption] if options[:caption].present?
      body[:fileName] = options[:filename] if options[:filename].present?

      request(:post, "/message/sendMedia/#{CGI.escape(instance_name)}", body)
    end

    private

    def evolution_api_url
      InstallationConfig.find_by(name: 'EVOLUTION_API_URL')&.value
    end

    def evolution_api_key
      InstallationConfig.find_by(name: 'EVOLUTION_API_KEY')&.value
    end

    def validate_configuration!
      raise ConfigurationError, 'Evolution API URL is not configured' if @base_url.blank?
      raise ConfigurationError, 'Evolution API Key is not configured' if @api_key.blank?
    end

    def request(method, path, body = nil)
      url = "#{@base_url}#{path}"
      options = {
        headers: headers,
        timeout: 30 # 30 second timeout
      }
      options[:body] = body.to_json if body.present?

      Rails.logger.debug("[Evolution API] #{method.upcase} #{url}")
      Rails.logger.debug("[Evolution API] Body: #{body.inspect}") if body.present?

      response = case method
                 when :get
                   HTTParty.get(url, options)
                 when :post
                   HTTParty.post(url, options)
                 when :put
                   HTTParty.put(url, options)
                 when :patch
                   HTTParty.patch(url, options)
                 when :delete
                   HTTParty.delete(url, options)
                 else
                   raise ArgumentError, "Unsupported HTTP method: #{method}"
                 end

      Rails.logger.debug("[Evolution API] Response code: #{response.code}")
      handle_response(response)
    end

    def headers
      {
        'apikey' => @api_key,
        'Content-Type' => 'application/json'
      }
    end

    def handle_response(response)
      body = response.parsed_response

      return body if response.success?

      error_message = extract_error_message(response)

      Rails.logger.error("[Evolution API] Error: #{response.code}")
      Rails.logger.error("[Evolution API] Response body: #{response.body}")
      Rails.logger.error("[Evolution API] Parsed response: #{body.inspect}")

      raise ApiError.new(error_message, status: response.code, response_body: body)
    end

    def extract_error_message(response)
      body = response.parsed_response

      return body if body.is_a?(String) && body.present?

      if body.is_a?(Hash)
        if body['response'].is_a?(Hash) && body['response']['message'].is_a?(Array)
          messages = body['response']['message'].join(', ')
          return messages if messages.present?
        end

        return body['response']['message'] if body['response'].is_a?(Hash) && body['response']['message'].present?
        return body['message'] if body['message'].present?
        return body['error']['message'] if body['error'].is_a?(Hash) && body['error']['message'].present?
        return body['error'] if body['error'].is_a?(String) && body['error'].present?
      end

      "Evolution API request failed with status #{response.code}"
    end
  end
end

