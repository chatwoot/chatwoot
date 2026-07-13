# frozen_string_literal: true

LAB_EMAIL = 'agentbot-admin@example.test'
LAB_PASSWORD = 'Password1!'
LAB_ENV_PATH = '/opt/agentbot-lab/.env.agent.local'

account = Account.find_or_create_by!(name: 'AgentBot Lab')

user = User.find_or_initialize_by(email: LAB_EMAIL)
if user.new_record?
  user.name = 'AgentBot Lab Admin'
  user.password = LAB_PASSWORD
  user.type = 'SuperAdmin'
  user.skip_confirmation!
  user.save!
end

AccountUser.find_or_create_by!(account: account, user: user) do |account_user|
  account_user.role = :administrator
end

channel = Channel::WebWidget.find_or_create_by!(account: account, website_url: 'http://localhost:3400') do |web_widget|
  web_widget.welcome_title = 'AgentBot Lab'
  web_widget.welcome_tagline = '독립 TypeScript AgentBot 서버 검증'
end

inbox = Inbox.find_or_create_by!(account: account, channel: channel) do |record|
  record.name = 'AgentBot Website Inbox'
end

InboxMember.find_or_create_by!(inbox: inbox, user: user)

agent_bot = AgentBot.find_or_create_by!(account: account, name: 'TypeScript AgentBot') do |bot|
  bot.description = 'Independent TypeScript agent server for the AgentBot lab'
  bot.outgoing_url = 'http://agent-server:3400/webhooks/chatwoot'
end
agent_bot.update!(outgoing_url: 'http://agent-server:3400/webhooks/chatwoot')

AgentBotInbox.find_or_create_by!(inbox: inbox, agent_bot: agent_bot).update!(status: :active)

values = {
  'CHATWOOT_ACCOUNT_ID' => account.id.to_s,
  'CHATWOOT_AGENT_BOT_ID' => agent_bot.id.to_s,
  'CHATWOOT_AGENT_BOT_TOKEN' => agent_bot.access_token.token,
  'CHATWOOT_WEBSITE_TOKEN' => channel.website_token,
  'CHATWOOT_WEBHOOK_SECRET' => agent_bot.secret
}

lines = File.exist?(LAB_ENV_PATH) ? File.readlines(LAB_ENV_PATH, chomp: true) : []
values.each do |key, value|
  index = lines.index { |line| line.start_with?("#{key}=") }
  index ? lines[index] = "#{key}=#{value}" : lines << "#{key}=#{value}"
end
File.write(LAB_ENV_PATH, "#{lines.join("\n")}\n")
File.chmod(0o600, LAB_ENV_PATH)

puts({
  account_id: account.id,
  inbox_id: inbox.id,
  agent_bot_id: agent_bot.id,
  website_token_configured: channel.website_token.present?,
  webhook_secret_configured: agent_bot.secret.present?,
  admin_email: LAB_EMAIL,
  admin_password: LAB_PASSWORD
}.to_json)
