# frozen_string_literal: true

require_relative 'lib/whatsapp_cutover'

required = %w[
  CUTOVER_TENANT
  WHATSAPP_PHONE_NUMBER
  WHATSAPP_PHONE_NUMBER_ID
  WHATSAPP_WABA_ID
  WHATSAPP_BUSINESS_PORTFOLIO_ID
  WHATSAPP_ACCESS_TOKEN
  WHATSAPP_APP_SECRET
]
missing = required.select { |key| ENV[key].to_s.empty? }
raise "Missing cutover variables: #{missing.join(', ')}" if missing.any?

tenant_key = ENV.fetch('CUTOVER_TENANT')
accounts = Account.where("custom_attributes ->> 'myinvest_tenant_key' = ?", tenant_key)
raise "Tenant not found: #{tenant_key}" if accounts.none?
raise "Ambiguous tenant: #{tenant_key}" if accounts.count > 1

account = accounts.first!
phone_number = ENV.fetch('WHATSAPP_PHONE_NUMBER')
service = Myinvest::WhatsappCutover::Service.new(
  account: account,
  phone_number: phone_number,
  phone_number_id: ENV.fetch('WHATSAPP_PHONE_NUMBER_ID'),
  waba_id: ENV.fetch('WHATSAPP_WABA_ID'),
  business_portfolio_id: ENV.fetch('WHATSAPP_BUSINESS_PORTFOLIO_ID'),
  access_token: ENV.fetch('WHATSAPP_ACCESS_TOKEN'),
  app_secret: ENV.fetch('WHATSAPP_APP_SECRET')
)

if ENV['DRY_RUN'] == 'true'
  redacted_phone = phone_number.gsub(/(?<=.{4}).(?=.{2})/, '*')
  puts "[WHATSAPP_CUTOVER] dry-run account_id=#{account.id} phone=#{redacted_phone}"
  exit 0
end

channel = service.perform

puts "WhatsApp cutover complete: inbox_id=#{channel.inbox.id} channel_id=#{channel.id}"
