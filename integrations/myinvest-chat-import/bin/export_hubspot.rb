#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/myinvest_chat_import'

begin
  output_path = ARGV.fetch(0)
  config = JSON.parse(ENV.fetch('HUBSPOT_EXPORT_CONFIG_JSON'))
  required_keys = %w[tenant_key inbox_ids channel_account_ids export_id]
  raise ArgumentError, 'invalid export configuration' unless config.is_a?(Hash) && config.keys.sort == required_keys.sort

  stats = MyinvestChatImport::HubspotExporter.new(
    client: MyinvestChatImport::HubspotClient.new(access_token: ENV.fetch('HUBSPOT_ACCESS_TOKEN')),
    output_path: output_path,
    tenant_key: config.fetch('tenant_key'),
    inbox_ids: config.fetch('inbox_ids'),
    channel_account_ids: config.fetch('channel_account_ids'),
    export_id: config.fetch('export_id')
  ).call
  puts JSON.generate(event: 'hubspot_history_export_completed', counts: stats)
rescue KeyError, JSON::ParserError, ArgumentError => error
  warn JSON.generate(event: 'hubspot_history_export_failed', error_code: 'invalid_configuration', error: error.message)
  exit 1
rescue MyinvestChatImport::HubspotClient::RequestError => error
  warn JSON.generate(event: 'hubspot_history_export_failed', error_code: 'hubspot_request_failed', error: error.message)
  exit 1
rescue StandardError
  warn JSON.generate(event: 'hubspot_history_export_failed', error_code: 'internal_export_error')
  exit 1
end
