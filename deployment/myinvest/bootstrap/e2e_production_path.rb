# frozen_string_literal: true

require 'fileutils'
require 'json'

raise 'Production E2E refuses LOCAL_SMOKE=true' if ENV.fetch('LOCAL_SMOKE', 'false') == 'true'

account = Account.where("custom_attributes ->> 'myinvest_tenant_key' = ?", 'saas').first!
inbox = account.inboxes.find_by!(name: "#{account.name} Website")
agent_bot = inbox.agent_bot
raise 'Managed AgentBot is missing' unless agent_bot

expected_url = "#{ENV.fetch('FRONTEND_URL').delete_suffix('/')}/_agent/webhooks/chatwoot"
raise 'Managed AgentBot URL is not the production endpoint' unless agent_bot.outgoing_url == expected_url

context = {
  account_id: account.id,
  website_token: inbox.channel.website_token
}
path = '/bootstrap-output/e2e-production.json'
File.write(path, JSON.generate(context), mode: 'w', perm: 0o600)
File.chmod(0o600, path)
