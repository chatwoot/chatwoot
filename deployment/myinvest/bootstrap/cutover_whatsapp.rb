# frozen_string_literal: true

require_relative 'lib/whatsapp_cutover'

module Myinvest
  module WhatsappCutover
    module Bootstrap
      class Runner
        class BootstrapError < StandardError; end

        SAFE_SERVICE_ERRORS = [
          Myinvest::WhatsappCutover::InputError,
          Myinvest::WhatsappCutover::ConflictError,
          Myinvest::WhatsappCutover::HealthError,
          Myinvest::WhatsappCutover::ConfigurationError
        ].freeze

        REQUIRED_VARIABLES = %w[
          CUTOVER_TENANT
          WHATSAPP_PHONE_NUMBER
          WHATSAPP_PHONE_NUMBER_ID
          WHATSAPP_WABA_ID
          WHATSAPP_BUSINESS_PORTFOLIO_ID
          WHATSAPP_ACCESS_TOKEN
          WHATSAPP_APP_SECRET
        ].freeze

        def self.run(env = ENV)
          new(env).run
        end

        def initialize(env)
          @env = env
        end

        def run
          validate_environment!
          account = lookup_account!
          service = build_service(account)

          if env['DRY_RUN'] == 'true'
            puts '[WHATSAPP_CUTOVER] dry run completed'
            return
          end

          channel = service.perform
          puts '[WHATSAPP_CUTOVER] completed'
          channel
        rescue *SAFE_SERVICE_ERRORS => e
          raise BootstrapError, e.message
        rescue BootstrapError
          raise
        rescue StandardError
          raise BootstrapError, 'WhatsApp cutover failed'
        end

        private

        attr_reader :env

        def validate_environment!
          missing = REQUIRED_VARIABLES.select { |key| env[key].to_s.empty? }
          raise BootstrapError, "Missing cutover variables: #{missing.join(', ')}" if missing.any?
        end

        def lookup_account!
          tenant_key = env.fetch('CUTOVER_TENANT')
          Account.where("custom_attributes ->> 'myinvest_tenant_key' = ?", tenant_key).sole
        rescue ActiveRecord::RecordNotFound
          raise BootstrapError, 'Tenant not found'
        rescue ActiveRecord::SoleRecordExceeded
          raise BootstrapError, 'Ambiguous tenant configuration'
        end

        def build_service(account)
          Myinvest::WhatsappCutover::Service.new(
            account: account,
            phone_number: env.fetch('WHATSAPP_PHONE_NUMBER'),
            phone_number_id: env.fetch('WHATSAPP_PHONE_NUMBER_ID'),
            waba_id: env.fetch('WHATSAPP_WABA_ID'),
            business_portfolio_id: env.fetch('WHATSAPP_BUSINESS_PORTFOLIO_ID'),
            access_token: env.fetch('WHATSAPP_ACCESS_TOKEN'),
            app_secret: env.fetch('WHATSAPP_APP_SECRET')
          )
        end
      end
    end
  end
end

Myinvest::WhatsappCutover::Bootstrap::Runner.run if __FILE__ == $PROGRAM_NAME
