#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
require 'json'
require 'net/http'
require 'uri'

module Myinvest
  module WhatsappCutover
    class HubspotChannelChecker
      def initialize(access_token:, channel_account_id:, base_uri: 'https://api.hubapi.com')
        raise ArgumentError, 'HubSpot access token is required' if access_token.to_s.empty?
        raise ArgumentError, 'HubSpot channel account ID is required' if channel_account_id.to_s.empty?

        @access_token = access_token
        @channel_account_id = channel_account_id
        @base_uri = URI(base_uri)
        raise ArgumentError, 'HubSpot endpoint must use HTTPS' unless @base_uri.is_a?(URI::HTTPS)
      end

      def cutover_allowed?
        account = fetch_channel_account
        raise 'HubSpot channel account not found; aborting cutover' if account.nil?

        active = account['active']
        authorized = account['authorized']
        active == false && authorized == false
      end

      private

      attr_reader :access_token, :channel_account_id, :base_uri

      def fetch_channel_account
        after = nil
        seen_afters = []

        loop do
          page = fetch_page(after)
          account = page['results'].find { |item| item['id'].to_s == channel_account_id.to_s }
          return account if account

          after = page.dig('paging', 'next', 'after')
          break if after.nil?
          raise 'HubSpot pagination error' if seen_afters.include?(after)

          seen_afters << after
        end
        nil
      end

      def fetch_page(after)
        uri = base_uri.dup
        uri.path = '/conversations/v3/conversations/channel-accounts'
        query = { limit: 100 }
        query[:after] = after if after
        uri.query = URI.encode_www_form(query)

        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{access_token}"
        request['Accept'] = 'application/json'

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
          http.request(request)
        end

        raise 'HubSpot API error' unless response.is_a?(Net::HTTPSuccess)

        parse_page(response.body)
      end

      def parse_page(body)
        parsed = JSON.parse(body)
        raise 'HubSpot response invalid' unless parsed.is_a?(Hash) && parsed['results'].is_a?(Array)

        parsed['results'].each do |item|
          raise 'HubSpot response invalid' unless valid_result?(item)
        end

        parsed
      rescue JSON::ParserError
        raise 'HubSpot response invalid'
      end

      def valid_result?(item)
        return false unless item.is_a?(Hash)
        return false unless item.key?('id')
        return false unless item['active'].is_a?(TrueClass) || item['active'].is_a?(FalseClass)
        return false unless item['authorized'].is_a?(TrueClass) || item['authorized'].is_a?(FalseClass)

        true
      end
    end

    class Wrapper
      REQUIRED_VARIABLES = %w[
        CUTOVER_CONFIRMATION
        CUTOVER_TENANT
        WHATSAPP_PHONE_NUMBER
        WHATSAPP_PHONE_NUMBER_ID
        WHATSAPP_WABA_ID
        WHATSAPP_BUSINESS_PORTFOLIO_ID
        WHATSAPP_ACCESS_TOKEN
        WHATSAPP_APP_SECRET
        HUBSPOT_ACCESS_TOKEN
        HUBSPOT_CHANNEL_ACCOUNT_ID
      ].freeze

      PASS_THROUGH_VARIABLES = %w[
        DRY_RUN
        CUTOVER_TENANT
        WHATSAPP_PHONE_NUMBER
        WHATSAPP_PHONE_NUMBER_ID
        WHATSAPP_WABA_ID
        WHATSAPP_BUSINESS_PORTFOLIO_ID
        WHATSAPP_ACCESS_TOKEN
        WHATSAPP_APP_SECRET
      ].freeze

      def initialize(env)
        @env = env
      end

      def run
        validate_confirmation!
        validate_required!
        verify_hubspot_channel_inactive!
        run_rails_provisioner!
      end

      private

      attr_reader :env

      def dry_run?
        env['DRY_RUN'] == 'true'
      end

      def validate_confirmation!
        expected = "cutover-whatsapp:#{env['CUTOVER_TENANT']}:#{env['WHATSAPP_PHONE_NUMBER']}"
        actual = env['CUTOVER_CONFIRMATION'].to_s
        return if actual == expected

        raise 'Confirmation mismatch; aborting cutover'
      end

      def validate_required!
        missing = REQUIRED_VARIABLES.select { |key| env[key].to_s.empty? }
        raise "Missing required variables: #{missing.join(', ')}" if missing.any?
      end

      def verify_hubspot_channel_inactive!
        checker = HubspotChannelChecker.new(
          access_token: env['HUBSPOT_ACCESS_TOKEN'],
          channel_account_id: env['HUBSPOT_CHANNEL_ACCOUNT_ID']
        )
        return if checker.cutover_allowed?

        raise 'HubSpot channel account is still active or authorized; aborting cutover'
      end

      def run_rails_provisioner!
        deployment_dir = File.expand_path('..', __dir__)
        env_path = env['ENV_FILE'] || File.join(deployment_dir, '.env')
        compose = [
          'docker', 'compose',
          '--project-directory', deployment_dir,
          '--env-file', env_path,
          '-f', File.join(deployment_dir, 'compose.yaml')
        ]

        environment_args = PASS_THROUGH_VARIABLES.flat_map { |key| ['-e', key] }

        command = compose + ['run', '--rm'] + environment_args + [
          '-e', 'WHATSAPP_CUTOVER_RUNNING=true',
          'rails', 'bundle', 'exec', 'rails', 'runner', '/bootstrap/cutover_whatsapp.rb'
        ]

        $stdout.puts '[WHATSAPP_CUTOVER] invoking Rails provisioner'
        $stdout.flush
        child_env = ENV.to_h
                       .merge(string_env)
                       .slice(*PASS_THROUGH_VARIABLES)
                       .merge('WHATSAPP_CUTOVER_RUNNING' => 'true')
        ok = system(child_env, *command)
        raise 'Rails provisioner failed' unless ok
      end

      def string_env
        env.each_with_object({}) do |(key, value), copy|
          copy[key.to_s] = value.nil? ? nil : value.to_s
        end
      end
    end
  end
end

Myinvest::WhatsappCutover::Wrapper.new(ENV).run if __FILE__ == $PROGRAM_NAME
