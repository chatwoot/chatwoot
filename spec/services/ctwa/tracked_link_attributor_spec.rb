require 'rails_helper'

RSpec.describe Ctwa::TrackedLinkAttributor do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+15551234567', provider: 'whatsapp_cloud', validate_provider_config: false,
                              sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:tracked_link) do
    Ctwa::TrackedLink.create!(account: account, inbox: inbox, name: 'QR Loja', code: 'ABC234')
  end

  describe '.attribute!' do
    it 'records a tracked link touch and increments the counter for a new conversation' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi #ABC234')

      described_class.attribute!(conversation, 'Oi #ABC234')

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']).to include(
        'source' => 'meta_organic',
        'source_id' => 'link:ABC234',
        'source_type' => 'tracked_link',
        'headline' => 'QR Loja'
      )
      expect(attrs['campaign_touches'].first).to include(
        'source_id' => 'link:ABC234',
        'source_type' => 'tracked_link',
        'headline' => 'QR Loja'
      )
      expect(tracked_link.reload.conversations_count).to eq(1)
    end

    it 'is a no-op when the code does not exist' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi #ZZZ999')

      described_class.attribute!(conversation, 'Oi #ZZZ999')

      expect(conversation.reload.additional_attributes).to be_blank
      expect(tracked_link.reload.conversations_count).to eq(0)
    end

    it 'is a no-op for an old conversation' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Mensagem anterior')
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi #ABC234')

      described_class.attribute!(conversation, 'Oi #ABC234')

      expect(conversation.reload.additional_attributes).to be_blank
      expect(tracked_link.reload.conversations_count).to eq(0)
    end

    it 'is a no-op when the message has no code' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi')

      described_class.attribute!(conversation, 'Oi')

      expect(conversation.reload.additional_attributes).to be_blank
      expect(tracked_link.reload.conversations_count).to eq(0)
    end
  end
end
