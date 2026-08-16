# frozen_string_literal: true

require 'logger'
require_relative '../lib/myinvest_chat_import'
require_relative '../lib/myinvest_chat_import/rails_adapter'

begin
  bundle_path = ARGV.fetch(0) { ENV.fetch('CHAT_IMPORT_BUNDLE_PATH') }
  identity = MyinvestChatImport::Identity.new(ENV.fetch('CHAT_IMPORT_HMAC_KEY'))
  bundle = MyinvestChatImport::Bundle.load(bundle_path)
  stats = ActiveRecord::Base.logger.silence(Logger::FATAL) do
    MyinvestChatImport::Importer.new(
      bundle: bundle,
      adapter: MyinvestChatImport::RailsAdapter.new,
      identity: identity
    ).call
  end

  puts JSON.generate(event: 'history_import_completed', tenant_key: bundle.tenant_key, counts: stats)
rescue KeyError
  warn JSON.generate(event: 'history_import_failed', error_code: 'missing_required_configuration')
  exit 1
rescue MyinvestChatImport::ImportError => error
  warn JSON.generate(event: 'history_import_failed', error_code: error.code)
  exit 1
rescue StandardError
  warn JSON.generate(event: 'history_import_failed', error_code: 'internal_import_error')
  exit 1
end
