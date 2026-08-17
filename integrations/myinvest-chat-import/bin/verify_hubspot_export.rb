#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/myinvest_chat_import'

begin
  path = ARGV.fetch(0) { ENV.fetch('CHAT_IMPORT_BUNDLE_PATH') }
  receipt = MyinvestChatImport::HubspotExportVerifier.new(path).call
  puts JSON.generate(receipt)
rescue KeyError
  warn JSON.generate(event: 'hubspot_history_export_verify_failed', error_code: 'missing_required_configuration')
  exit 1
rescue MyinvestChatImport::ImportError => error
  warn JSON.generate(event: 'hubspot_history_export_verify_failed', error_code: error.code)
  exit 1
rescue StandardError
  warn JSON.generate(event: 'hubspot_history_export_verify_failed', error_code: 'internal_verify_error')
  exit 1
end
