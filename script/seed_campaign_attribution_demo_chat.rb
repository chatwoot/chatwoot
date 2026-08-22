# frozen_string_literal: true
# Demo conversation attributed to a WhatsApp campaign (badge + filter testing).
# Usage: bundle exec rails runner script/seed_campaign_attribution_demo_chat.rb

account = Account.find_by(id: 1) || Account.first
raise 'No account found' unless account

account.enable_features!('whatsapp_campaign')

WAMID = 'wamid.demo.campaign.attribution.1'
CONTACT_PHONE = '+593989990001'
CONTACT_NAME = 'María Demo Campaña'
CAMPAIGN_TITLE = 'DEMO — Promo Verano 2026'

channel = Channel::Whatsapp.find_by(account_id: account.id, phone_number: '+593980000001')
if channel.nil?
  channel = Channel::Whatsapp.new(
    account: account,
    phone_number: '+593980000001',
    provider: 'whatsapp_cloud',
    provider_config: {
      'api_key' => 'demo_local_key_not_real',
      'phone_number_id' => 'demo_phone_number_id',
      'business_account_id' => 'demo_waba_id',
      'webhook_verify_token' => SecureRandom.hex(16)
    },
    message_templates: [
      {
        'name' => 'promo_demo',
        'status' => 'APPROVED',
        'category' => 'MARKETING',
        'language' => 'es',
        'components' => [{ 'type' => 'BODY', 'text' => 'Hola {{1}}, ¿te interesa nuestra promo de verano?' }]
      }
    ]
  )
  channel.save!(validate: false)
end

inbox = channel.inbox || Inbox.create!(account: account, channel: channel, name: 'Demo WhatsApp | 0980000001')
inbox.update!(name: 'Demo WhatsApp | 0980000001') if inbox.name.blank?

account.administrators.find_each do |user|
  InboxMember.find_or_create_by!(inbox: inbox, user: user)
end

campaign = account.campaigns.find_by(title: CAMPAIGN_TITLE)
if campaign.nil?
  label = account.labels.find_or_create_by!(title: 'demo_campaign') do |l|
    l.color = '#1f93ff'
    l.show_on_sidebar = true
  end

  campaign = account.campaigns.create!(
    inbox: inbox,
    title: CAMPAIGN_TITLE,
    message: 'Hola {{1}}, ¿te interesa nuestra promo de verano?',
    campaign_type: :one_off,
    campaign_status: :completed,
    scheduled_at: 2.hours.ago,
    completed_at: 1.hour.ago,
    audience: [{ 'type' => 'Label', 'id' => label.id }],
    template_params: {
      'name' => 'promo_demo',
      'language' => 'es',
      'category' => 'MARKETING',
      'processed_params' => { 'body' => { '1' => 'María' } }
    }
  )
end

contact = account.contacts.find_by(phone_number: CONTACT_PHONE)
contact ||= account.contacts.create!(name: CONTACT_NAME, phone_number: CONTACT_PHONE)
contact.update!(name: CONTACT_NAME)

contact_inbox = ContactInbox.find_by(inbox: inbox, contact: contact)
contact_inbox ||= ContactInbox.create!(inbox: inbox, contact: contact, source_id: CONTACT_PHONE.delete('+'))

recipient = campaign.campaign_recipients.find_or_initialize_by(contact: contact)
recipient.assign_attributes(
  account: account,
  inbox: inbox,
  phone_number: CONTACT_PHONE,
  status: :read,
  source_id: WAMID,
  sent_at: 30.minutes.ago,
  delivered_at: 29.minutes.ago,
  read_at: 25.minutes.ago,
  message_content: 'Hola María, ¿te interesa nuestra promo de verano?'
)
recipient.save!

conversation = contact.conversations.find_by(inbox: inbox, campaign_id: campaign.id)
unless conversation
  conversation = Conversation.create!(
    account: account,
    inbox: inbox,
    contact: contact,
    contact_inbox: contact_inbox,
    campaign_id: campaign.id,
    status: :open
  )
end

template_message = conversation.messages.find_by(source_id: WAMID)
unless template_message
  template_message = conversation.messages.create!(
    account: account,
    inbox: inbox,
    conversation: conversation,
    message_type: :outgoing,
    content: recipient.message_content,
    source_id: WAMID,
    sender: campaign.sender || account.administrators.first
  )
end

reply_body = 'Sí, me interesa'
reply_source_id = 'wamid.demo.campaign.attribution.reply.1'
unless conversation.messages.exists?(source_id: reply_source_id)
  conversation.messages.create!(
    account: account,
    inbox: inbox,
    conversation: conversation,
    message_type: :incoming,
    content: reply_body,
    source_id: reply_source_id,
    content_attributes: {
      in_reply_to: template_message.id,
      in_reply_to_external_id: WAMID
    },
    sender: contact
  )
end

conversation.update!(last_activity_at: Time.current)

puts({
  ok: true,
  account_id: account.id,
  inbox_id: inbox.id,
  inbox_name: inbox.name,
  campaign_display_id: campaign.display_id,
  campaign_title: campaign.title,
  conversation_display_id: conversation.display_id,
  contact_name: contact.name,
  contact_phone: contact.phone_number,
  open_url_hint: "/app/accounts/#{account.id}/conversations/#{conversation.display_id}",
  filter_hint: "Nombre de campaña → #{campaign.title}",
  note: 'Conversación atribuida a campaña WA (simula respuesta con botón/context).'
}.to_json)
