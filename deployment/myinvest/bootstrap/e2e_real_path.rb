# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'securerandom'

raise 'LOCAL_SMOKE=true is required' unless ENV.fetch('LOCAL_SMOKE') == 'true'

ActiveJob::Base.queue_adapter = :inline
account = Account.where("custom_attributes ->> 'myinvest_tenant_key' = ?", 'saas').first!
inbox = account.inboxes.find_by!(name: "#{account.name} Website")
agent_bot = inbox.agent_bot
raise 'Managed AgentBot is missing' unless agent_bot

contact = account.contacts.create!(name: "Local Real-Path E2E #{SecureRandom.hex(4)}")
contact_inbox = ContactInbox.create!(
  contact: contact, inbox: inbox, source_id: SecureRandom.uuid
)
conversation = Conversation.create!(
  account: account, contact: contact, contact_inbox: contact_inbox,
  inbox: inbox, status: :pending
)

original_url = agent_bot.outgoing_url
begin
  agent_bot.update!(outgoing_url: ENV.fetch('E2E_AGENT_URL'))
  message = Message.create!(
    account: account,
    inbox: inbox,
    conversation: conversation,
    sender: contact,
    message_type: :incoming,
    content: 'Kontoeinrichtung',
    private: false
  )
ensure
  agent_bot.update!(outgoing_url: original_url)
end

context = {
  conversation_id: conversation.id,
  conversation_display_id: conversation.display_id,
  message_id: message.id
}
path = '/bootstrap-output/e2e-real.json'
File.write(path, JSON.generate(context), mode: 'w', perm: 0o600)
File.chmod(0o600, path)
