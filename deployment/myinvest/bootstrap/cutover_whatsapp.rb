# frozen_string_literal: true

require_relative 'lib/whatsapp_cutover'

required = %w[
  CUTOVER_TENANT
  WHATSAPP_PHONE_NUMBER
  WHATSAPP_PHONE_NUMBER_ID
  WHATSAPP_WABA_ID
  WHATSAPP_ACCESS_TOKEN
  WHATSAPP_APP_SECRET
]
missing = required.select { |key| ENV[key].to_s.empty? }
raise "Missing cutover variables: #{missing.join(', ')}" if missing.any?

tenant_key = ENV.fetch('CUTOVER_TENANT')
account = Account.find_by("custom_attributes ->> 'myinvest_tenant_key' = ?", tenant_key)
raise "Tenant not found: #{tenant_key}" unless account

service = Myinvest::WhatsappCutover::Service.new(
  account: account,
  phone_number: ENV.fetch('WHATSAPP_PHONE_NUMBER'),
  phone_number_id: ENV.fetch('WHATSAPP_PHONE_NUMBER_ID'),
  waba_id: ENV.fetch('WHATSAPP_WABA_ID'),
  access_token: ENV.fetch('WHATSAPP_ACCESS_TOKEN'),
  app_secret: ENV.fetch('WHATSAPP_APP_SECRET'),
  override_callback_url: ENV['WHATSAPP_OVERRIDE_CALLBACK_URL']
)

if ENV['DRY_RUN'] == 'true'
  puts "[WHATSAPP_CUTOVER] dry-run account_id=#{account.id} phone=#{ENV.fetch('WHATSAPP_PHONE_NUMBER')}"
  exit 0
end

channel = service.perform

puts "WhatsApp cutover complete: inbox_id=#{channel.inbox.id} channel_id=#{channel.id}"
