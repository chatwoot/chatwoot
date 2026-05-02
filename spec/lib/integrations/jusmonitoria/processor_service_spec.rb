require 'rails_helper'

RSpec.describe Integrations::Jusmonitoria::ProcessorService do
  describe '#inbox_payload' do
    it 'includes the WhatsApp provider so JusMonitorIA can choose template or text delivery' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      processor = described_class.new(event_name: 'message.created', hook: instance_double(Integrations::Hook, id: 1), event_data: {})

      payload = processor.send(:inbox_payload, channel.inbox)

      expect(payload).to include(
        id: channel.inbox.id,
        channel_type: 'Channel::Whatsapp',
        provider: 'whatsapp_cloud'
      )
    end
  end
end
