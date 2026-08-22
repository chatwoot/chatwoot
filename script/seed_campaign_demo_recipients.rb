# frozen_string_literal: true
# Seed demo WhatsApp campaign recipients for local UI preview (no Meta needed).
# Usage: bundle exec rails runner script/seed_campaign_demo_recipients.rb

account = Account.find_by(id: 1) || Account.first
raise 'No account found' unless account

account.enable_features!('whatsapp_campaign')

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
        'components' => [{ 'type' => 'BODY', 'text' => 'Hola {{1}}, promo demo InboxHub.' }]
      }
    ]
  )
  channel.save!(validate: false)
end

inbox = channel.inbox || Inbox.create!(
  account: account,
  channel: channel,
  name: 'Demo WhatsApp | 0980000001'
)
inbox.update!(name: 'Demo WhatsApp | 0980000001') if inbox.name.blank?

# Ensure inbox members so admins can see it
account.administrators.find_each do |user|
  InboxMember.find_or_create_by!(inbox: inbox, user: user)
end

label = account.labels.find_or_create_by!(title: 'demo_campaign') do |l|
  l.color = '#1f93ff'
  l.show_on_sidebar = true
end

campaign = account.campaigns.find_by(title: 'DEMO — Visibilidad de envíos')
if campaign.nil?
  campaign = account.campaigns.create!(
    inbox: inbox,
    title: 'DEMO — Visibilidad de envíos',
    message: 'Hola {{1}}, promo demo InboxHub.',
    campaign_type: :one_off,
    campaign_status: :completed,
    scheduled_at: 1.hour.ago,
    audience: [{ 'type' => 'Label', 'id' => label.id }],
    template_params: {
      'name' => 'promo_demo',
      'language' => 'es',
      'category' => 'MARKETING',
      'processed_params' => { 'body' => { '1' => 'Cliente' } }
    }
  )
else
  campaign.update!(
    inbox: inbox,
    campaign_status: :completed,
    audience: [{ 'type' => 'Label', 'id' => label.id }]
  )
end

campaign.campaign_recipients.destroy_all

samples = [
  { name: 'Ana Enviado', phone: '+593981111001', status: :sent, hours_ago: 2 },
  { name: 'Bruno Entregado', phone: '+593981111002', status: :delivered, hours_ago: 3 },
  { name: 'Carla Leído', phone: '+593981111003', status: :read, hours_ago: 4 },
  { name: 'Diego Fallido', phone: '+593981111004', status: :failed, hours_ago: 5, error: '131026: Message undeliverable' },
  { name: 'Elena Omitido', phone: nil, status: :skipped, hours_ago: 5, error: 'no phone number' },
  { name: 'Felipe Pendiente', phone: '+593981111006', status: :queued, hours_ago: 1 },
  { name: 'Gina Entregado 2', phone: '+593981111007', status: :delivered, hours_ago: 2 },
  { name: 'Hugo Leído 2', phone: '+593981111008', status: :read, hours_ago: 1 },
  { name: 'Irene Enviado 2', phone: '+593981111009', status: :sent, hours_ago: 1 },
  { name: 'Jorge Fallido 2', phone: '+593981111010', status: :failed, hours_ago: 2, error: '131047: Re-engagement message' },
  { name: 'Karen Delivered 3', phone: '+593981111011', status: :delivered, hours_ago: 6 },
  { name: 'Luis Read 3', phone: '+593981111012', status: :read, hours_ago: 6 }
]

samples.each_with_index do |sample, idx|
  contact = if sample[:phone].present?
              account.contacts.find_by(phone_number: sample[:phone]) ||
                account.contacts.create!(name: sample[:name], phone_number: sample[:phone])
            else
              account.contacts.find_by(name: sample[:name]) ||
                account.contacts.create!(name: sample[:name])
            end
  contact.update_labels([label.title]) unless contact.label_list.include?(label.title)

  sent_at = sample[:hours_ago].hours.ago
  attrs = {
    account: account,
    contact: contact,
    phone_number: sample[:phone],
    status: sample[:status],
    error_message: sample[:error],
    source_id: sample[:status] == :skipped || sample[:status] == :queued ? nil : "wamid.demo.#{idx + 1}"
  }

  attrs[:inbox] = inbox

  case sample[:status]
  when :sent
    attrs[:sent_at] = sent_at
  when :delivered
    attrs[:sent_at] = sent_at
    attrs[:delivered_at] = sent_at + 2.minutes
  when :read
    attrs[:sent_at] = sent_at
    attrs[:delivered_at] = sent_at + 2.minutes
    attrs[:read_at] = sent_at + 10.minutes
  when :failed
    attrs[:sent_at] = sent_at
    attrs[:failed_at] = sent_at + 1.minute
  end

  campaign.campaign_recipients.create!(attrs)
end

campaign.refresh_execution_stats!

puts({
  account_id: account.id,
  account: account.name,
  inbox_id: inbox.id,
  inbox: inbox.name,
  campaign_display_id: campaign.display_id,
  campaign_title: campaign.title,
  recipients: campaign.campaign_recipients.count,
  execution_stats: campaign.execution_stats,
  whatsapp_campaign_enabled: account.feature_enabled?(:whatsapp_campaign)
}.inspect)
