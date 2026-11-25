require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Coverage do
  let(:channel) { create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, inbox: inbox, account: inbox.account) }

  describe '.watermark' do
    it 'is nil for an inbox that never stored a provider message' do
      expect(described_class.watermark(inbox)).to be_nil
    end

    it 'is the newest message that came from the provider' do
      create(:message, conversation: conversation, inbox: inbox, source_id: 'A', created_at: 3.days.ago)
      newest = create(:message, conversation: conversation, inbox: inbox, source_id: 'B', created_at: 1.day.ago)

      expect(described_class.watermark(inbox)).to be_within(1.second).of(newest.created_at)
    end

    # An agent typing a private note says the dashboard was in use, not that the channel
    # was up. Counting it would date the coverage past the outage it is meant to measure,
    # and every message from the weekend would then read as history nobody needs to see.
    it 'ignores rows that did not come from the provider' do
      create(:message, conversation: conversation, inbox: inbox, source_id: 'A', created_at: 3.days.ago)
      create(:message, conversation: conversation, inbox: inbox, source_id: nil, private: true, created_at: 1.minute.ago)

      expect(described_class.watermark(inbox)).to be_within(1.second).of(3.days.ago)
    end

    # A dump arrives in several frames, each filed on its own. With imported rows counted,
    # the second frame would measure itself against what the first one just wrote and file
    # the rest of the outage as archive.
    it 'ignores rows an import filed after the fact' do
      create(:message, conversation: conversation, inbox: inbox, source_id: 'A', created_at: 3.days.ago)
      create(:message, conversation: conversation, inbox: inbox, source_id: 'B', created_at: 1.day.ago,
                       content_attributes: { imported: true })

      expect(described_class.watermark(inbox)).to be_within(1.second).of(3.days.ago)
    end
  end

  describe '.gap?' do
    let(:message) do
      Whatsapp::Session::Model::InboundMessage.new(
        id: 'X', chat: Whatsapp::Session::Model::Address.phone('5541999990000'), from_me: false,
        timestamp: 2.days.ago.to_i * 1000, content: Whatsapp::Session::Model::Content::Text.new(body: 'oi')
      )
    end

    it 'is true for a message that arrived after the inbox stopped listening' do
      expect(described_class.gap?(message, 3.days.ago)).to be(true)
    end

    it 'is false for a message the inbox was already covering' do
      expect(described_class.gap?(message, 1.day.ago)).to be(false)
    end

    # A first connection: nothing predates coverage that has not also predated the inbox,
    # so the whole dump is archive and a freshly paired inbox opens no threads at all.
    it 'is false when the inbox has no coverage yet' do
      expect(described_class.gap?(message, nil)).to be(false)
    end
  end
end
