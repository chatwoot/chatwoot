# frozen_string_literal: true

require 'fileutils'
require 'json'

required = %w[
  ADMIN_NAME ADMIN_EMAIL MYINVEST_ACCOUNT_NAME
  ACADEMY_NEW_ACCOUNT_NAME ACADEMY_LEGACY_ACCOUNT_NAME
  MYINVEST_WEBSITE_URL ACADEMY_NEW_WEBSITE_URL ACADEMY_LEGACY_WEBSITE_URL
]
missing = required.select { |key| ENV[key].blank? }
raise "Missing bootstrap variables: #{missing.join(', ')}" if missing.any?

admin = User.from_email(ENV.fetch('ADMIN_EMAIL'))
unless admin
  raise 'ADMIN_PASSWORD is required when creating the initial administrator' if ENV['ADMIN_PASSWORD'].blank?

  admin = User.new(
    name: ENV.fetch('ADMIN_NAME'),
    email: ENV.fetch('ADMIN_EMAIL'),
    password: ENV.fetch('ADMIN_PASSWORD'),
    password_confirmation: ENV.fetch('ADMIN_PASSWORD'),
    type: 'SuperAdmin'
  )
  admin.skip_confirmation!
  admin.save!
end

account_names = [
  ['saas', ENV.fetch('MYINVEST_ACCOUNT_NAME'), ENV.fetch('MYINVEST_WEBSITE_URL')],
  ['new_academy', ENV.fetch('ACADEMY_NEW_ACCOUNT_NAME'), ENV.fetch('ACADEMY_NEW_WEBSITE_URL')],
  ['legacy_academy', ENV.fetch('ACADEMY_LEGACY_ACCOUNT_NAME'), ENV.fetch('ACADEMY_LEGACY_WEBSITE_URL')]
]

tenant_credentials = []
ActiveRecord::Base.transaction do
  account_names.each do |key, name, website_url|
    account = Account.where("custom_attributes ->> 'myinvest_tenant_key' = ?", key).first
    account ||= Account.find_by(name: name)
    account ||= Account.new
    account.name = name
    account.locale = :de
    account.custom_attributes = account.custom_attributes.merge(
      'managed_by' => 'myinvest-bootstrap',
      'myinvest_tenant_key' => key
    )
    account.save!
    AccountUser.find_or_create_by!(account: account, user: admin) do |membership|
      membership.role = :administrator
    end

    agent_bot = AgentBot.find_or_initialize_by(account: account, name: 'MyInvest Claude Support')
    agent_bot.description = "Tenant-scoped Claude handoff for #{name}"
    agent_bot.outgoing_url = "#{ENV.fetch('FRONTEND_URL').delete_suffix('/')}/_agent/webhooks/chatwoot"
    agent_bot.save!

    inbox_name = "#{name} Website"
    inbox = Inbox.find_by(account: account, name: inbox_name)
    unless inbox
      channel = Channel::WebWidget.create!(
        account: account,
        website_url: website_url,
        welcome_title: "Willkommen beim #{name} Support",
        welcome_tagline: 'Wie können wir helfen?'
      )
      inbox = Inbox.create!(account: account, channel: channel, name: inbox_name)
    end
    raise "Managed inbox is not a website inbox: #{inbox_name}" unless inbox.channel.is_a?(Channel::WebWidget)

    InboxMember.find_or_create_by!(inbox: inbox, user: admin)
    bot_inbox = AgentBotInbox.find_or_initialize_by(inbox: inbox)
    bot_inbox.agent_bot = agent_bot
    bot_inbox.status = :active
    bot_inbox.save!

    tenant_credentials << {
      key: key,
      accountId: account.id,
      webhookSecret: agent_bot.secret,
      agentBotToken: agent_bot.access_token.token,
      websiteToken: inbox.channel.website_token
    }
  end
end

output_directory = '/bootstrap-output'
FileUtils.mkdir_p(output_directory, mode: 0o700)
temporary_path = File.join(output_directory, "tenants.json.tmp.#{Process.pid}")
output_path = File.join(output_directory, 'tenants.json')
File.write(temporary_path, JSON.generate(tenant_credentials), mode: 'w', perm: 0o600)
File.rename(temporary_path, output_path)
File.chmod(0o600, output_path)

puts "Bootstrap complete: #{account_names.length} account boundaries, website inboxes, and Agent Bots."
