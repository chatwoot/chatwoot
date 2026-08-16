# frozen_string_literal: true

require 'securerandom'
require 'uri'

module Myinvest
  module WhatsappCutover
    class ConflictError < StandardError; end
    class HealthError < StandardError; end
    class ConfigurationError < StandardError; end

    class Service
      REQUIRED_STATUS = 'CONNECTED'
      REQUIRED_CODE_VERIFICATION = 'VERIFIED'
      REQUIRED_PLATFORM_TYPE = 'CLOUD_API'
      RISKY_QUALITY_RATINGS = %w[YELLOW RED].freeze
      E164_REGEX = /\A\+[1-9]\d{1,14}\z/.freeze
      DECIMAL_ID_REGEX = /\A\d+\z/.freeze

      attr_reader :account, :phone_number, :phone_number_id, :waba_id, :business_portfolio_id, :access_token, :app_secret

      def initialize(account:, phone_number:, phone_number_id:, waba_id:, business_portfolio_id:, access_token:, app_secret:)
        @account = account
        @phone_number = phone_number.to_s.strip
        @phone_number_id = phone_number_id.to_s.strip
        @waba_id = waba_id.to_s.strip
        @business_portfolio_id = business_portfolio_id.to_s.strip
        @access_token = access_token.to_s
        @app_secret = app_secret.to_s
        validate_parameters!
      end

      def perform
        channel = find_or_create_channel!
        setup_webhook!(channel)
        verify_health!(channel)
        attach_agent_bot!(channel)
        assign_admin!(channel)
        channel
      end

      private

      def validate_parameters!
        raise ArgumentError, 'Account is required' if account.blank?
        raise ArgumentError, 'Phone number is required' if phone_number.blank?
        raise ArgumentError, 'Phone number must be a valid E.164 number' unless phone_number.match?(E164_REGEX)
        raise ArgumentError, 'Phone number ID is required' if phone_number_id.blank?
        raise ArgumentError, 'Phone number ID must be a numeric string' unless phone_number_id.match?(DECIMAL_ID_REGEX)
        raise ArgumentError, 'WABA ID is required' if waba_id.blank?
        raise ArgumentError, 'WABA ID must be a numeric string' unless waba_id.match?(DECIMAL_ID_REGEX)
        raise ArgumentError, 'Business portfolio ID is required' if business_portfolio_id.blank?
        raise ArgumentError, 'Business portfolio ID must be a numeric string' unless business_portfolio_id.match?(DECIMAL_ID_REGEX)
        raise ArgumentError, 'Access token is required' if access_token.blank?
        raise ArgumentError, 'App secret is required' if app_secret.blank?
      end

      def find_or_create_channel!
        existing = Channel::Whatsapp.find_by(phone_number: phone_number)
        if existing
          validate_ownership!(existing)
          apply_provider_config!(existing)
          return existing
        end

        ActiveRecord::Base.transaction do
          channel = Channel::Whatsapp.build(
            account: account,
            phone_number: phone_number,
            provider: 'whatsapp_cloud',
            provider_config: build_provider_config
          )
          Inbox.create!(account: account, name: build_inbox_name, channel: channel)
          channel
        end
      end

      def validate_ownership!(channel)
        if channel.account_id != account.id
          raise ConflictError, 'Phone number already belongs to another account; cross-account cutover rejected'
        end

        config = channel.provider_config || {}
        existing_waba = config['business_account_id'].to_s
        existing_phone_id = config['phone_number_id'].to_s

        if existing_waba.present? && existing_waba != waba_id
          raise ConflictError, 'Existing phone number is registered under a different WABA; cutover rejected'
        end

        if existing_phone_id.present? && existing_phone_id != phone_number_id
          raise ConflictError, 'Existing phone number is registered with a different phone number ID; cutover rejected'
        end

        true
      end

      def apply_provider_config!(channel)
        config = (channel.provider_config || {}).dup
        channel.provider_config = config.merge(build_provider_config(existing: config))
        channel.save!
      end

      def build_provider_config(existing: {})
        {
          'api_key' => access_token,
          'phone_number_id' => phone_number_id,
          'business_account_id' => waba_id,
          'app_secret' => app_secret,
          'source' => existing['source'].presence || 'embedded_signup',
          'webhook_verify_token' => existing['webhook_verify_token'].presence || SecureRandom.hex(16)
        }
      end

      def build_inbox_name
        "#{account.name} WhatsApp"
      end

      def setup_webhook!(channel)
        Whatsapp::WebhookSetupService.new(channel, waba_id, access_token).perform
      end

      def verify_health!(channel)
        health = fetch_health(channel)
        verify_phone!(health)
        verify_phone_id!(health)
        verify_waba!(health)
        verify_business_portfolio!(health)
        verify_connected_status!(health)
        verify_code_verification!(health)
        verify_platform_type!(health)
        verify_quality_rating!(health)
        verify_webhook!(health)

        Rails.logger.info("[WHATSAPP_CUTOVER] health verified account_id=#{account.id} channel_id=#{channel.id}")
      end

      def fetch_health(channel)
        Whatsapp::HealthService.new(channel).fetch_health_status
      rescue HealthError
        raise
      rescue StandardError
        raise HealthError, 'Health check failed'
      end

      def verify_phone_id!(health)
        actual_id = health[:id].to_s
        return if actual_id.present? && actual_id == phone_number_id

        raise HealthError, 'Health check failed: phone number ID mismatch'
      end

      def verify_phone!(health)
        actual_phone = health[:display_phone_number].to_s.strip
        return if actual_phone == phone_number

        raise HealthError, 'Health check failed: phone number mismatch'
      end

      def verify_waba!(health)
        actual_waba = health[:business_account_id].to_s
        return if actual_waba.present? && actual_waba == waba_id

        raise HealthError, 'Health check failed: WABA mismatch'
      end

      def verify_business_portfolio!(health)
        portfolio_id = health[:business_portfolio_id].to_s
        return if portfolio_id.present? && portfolio_id == business_portfolio_id

        raise HealthError, 'Health check failed: business portfolio mismatch'
      end

      def verify_connected_status!(health)
        status = health[:status].to_s
        return if status == REQUIRED_STATUS

        raise HealthError, 'Health check failed: status mismatch'
      end

      def verify_code_verification!(health)
        status = health[:code_verification_status].to_s
        return if status == REQUIRED_CODE_VERIFICATION

        raise HealthError, 'Health check failed: code verification mismatch'
      end

      def verify_platform_type!(health)
        platform_type = health[:platform_type].to_s
        return if platform_type == REQUIRED_PLATFORM_TYPE

        raise HealthError, 'Health check failed: platform type mismatch'
      end

      def verify_quality_rating!(health)
        rating = health[:quality_rating].to_s
        return if rating.present? && RISKY_QUALITY_RATINGS.exclude?(rating)

        raise HealthError, 'Health check failed: quality rating mismatch'
      end

      def verify_webhook!(health)
        actual = webhook_override_callback_uri(health)
        raise HealthError, 'Health check failed: webhook callback missing' if actual.blank?

        expected = expected_webhook_url
        return if actual == expected

        raise HealthError, 'Health check failed: webhook callback mismatch'
      end

      def webhook_override_callback_uri(health)
        config = health[:webhook_configuration]
        config = {} unless config.is_a?(Hash)

        config['override_callback_uri'].to_s
      end

      def expected_webhook_url
        "#{strict_frontend_origin}/webhooks/whatsapp/#{phone_number}"
      end

      def strict_frontend_origin
        url = ENV.fetch('FRONTEND_URL', '')
        raise HealthError, 'Health check failed: FRONTEND_URL is not configured' if url.blank?

        uri = URI.parse(url)
        raise HealthError, 'Health check failed: FRONTEND_URL must use HTTPS' unless uri.is_a?(URI::HTTPS)
        raise HealthError, 'Health check failed: FRONTEND_URL must not contain userinfo' if uri.userinfo.present?
        raise HealthError, 'Health check failed: FRONTEND_URL must not contain a query string' if uri.query.present?
        raise HealthError, 'Health check failed: FRONTEND_URL must not contain a fragment' if uri.fragment.present?

        host = uri.host.to_s.downcase
        raise HealthError, 'Health check failed: FRONTEND_URL host is missing' if host.blank?

        port = uri.port
        if port == uri.default_port
          "https://#{host}"
        else
          "https://#{host}:#{port}"
        end
      rescue URI::InvalidURIError
        raise HealthError, 'Health check failed: FRONTEND_URL is invalid'
      end

      def attach_agent_bot!(channel)
        agent_bot = AgentBot.find_by(account: account, name: 'MyInvest Claude Support')
        raise ConfigurationError, 'Agent bot MyInvest Claude Support not found' unless agent_bot

        bot_inbox = AgentBotInbox.find_or_initialize_by(inbox: channel.inbox)
        bot_inbox.agent_bot = agent_bot
        bot_inbox.status = :active
        bot_inbox.save!

        Rails.logger.info("[WHATSAPP_CUTOVER] agent_bot attached account_id=#{account.id} channel_id=#{channel.id} agent_bot_id=#{agent_bot.id}")
      end

      def assign_admin!(channel)
        admin_membership = AccountUser.find_by(account: account, role: :administrator)
        raise ConfigurationError, 'No account administrator found' unless admin_membership&.user

        InboxMember.find_or_create_by!(inbox: channel.inbox, user: admin_membership.user)
        Rails.logger.info("[WHATSAPP_CUTOVER] admin assigned account_id=#{account.id} channel_id=#{channel.id} user_id=#{admin_membership.user_id}")
      end
    end
  end
end
