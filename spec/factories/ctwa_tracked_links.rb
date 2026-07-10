FactoryBot.define do
  factory :ctwa_tracked_link, class: 'Ctwa::TrackedLink' do
    account
    name { 'QR Loja' }
    prefilled_text { 'Quero atendimento' }

    inbox do
      channel = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      channel.inbox
    end
  end
end
