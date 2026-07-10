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
  let(:click) do
    create(:ctwa_tracked_link_click, account: account, tracked_link: tracked_link, token: 'ABCD2345',
                                     params: {
                                       'gclid' => 'gclid-123',
                                       'utm_campaign' => 'july',
                                       'utm_term' => 'running shoes',
                                       'utm_content' => 'blue creative'
                                     })
  end

  describe '.attribute!' do
    it 'records a tracked link touch and increments the counter for a new conversation' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi #ABC234')

      described_class.attribute!(conversation, 'Oi #ABC234')

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']).to include(
        'source' => 'tracked_link',
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

    it 'does not increment the counter when a tracked link code is redelivered' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi #ABC234')

      described_class.attribute!(conversation, 'Oi #ABC234')
      described_class.attribute!(conversation, 'Oi #ABC234')

      expect(conversation.reload.additional_attributes['campaign_touches'].length).to eq(1)
      expect(tracked_link.reload.conversations_count).to eq(1)
    end

    it 'does not attribute a tracked link code in a non-first inbound message' do
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

    it 'records a bridge touch from a click token, consumes the click and increments the counter' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: "Oi ##{click.token}")

      described_class.attribute!(conversation, "Oi ##{click.token}")

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']).to include(
        'source' => 'google_ads',
        'source_id' => "click:#{click.token}",
        'source_type' => 'bridge',
        'headline' => 'QR Loja',
        'gclid' => 'gclid-123',
        'utm_campaign' => 'july',
        'utm_term' => 'running shoes',
        'utm_content' => 'blue creative'
      )
      expect(attrs['campaign_touches'].first).to include(
        'source' => 'google_ads',
        'source_id' => "click:#{click.token}",
        'source_type' => 'bridge',
        'utm_term' => 'running shoes',
        'utm_content' => 'blue creative'
      )
      expect(click.reload.conversation_id).to eq(conversation.id)
      expect(tracked_link.reload.conversations_count).to eq(1)
    end

    it 'does not attribute a click token from a different inbox' do
      other_channel = create(:channel_whatsapp, account: account, phone_number: '+15559876543', provider: 'whatsapp_cloud',
                                                validate_provider_config: false, sync_templates: false)
      other_link = Ctwa::TrackedLink.create!(account: account, inbox: other_channel.inbox, name: 'QR Outra Loja', code: 'XYZ789')
      other_click = create(:ctwa_tracked_link_click, account: account, tracked_link: other_link, token: 'ZZZZ9999',
                                                     params: { 'gclid' => 'other-gclid' })

      create(:message, conversation: conversation, account: account, inbox: inbox, content: "Oi ##{other_click.token}")

      described_class.attribute!(conversation, "Oi ##{other_click.token}")

      expect(conversation.reload.additional_attributes).to be_blank
      expect(other_click.reload.conversation_id).to be_nil
      expect(other_link.reload.conversations_count).to eq(0)
    end

    it 'does not attribute a click token in a non-first inbound message' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Mensagem anterior')
      create(:message, conversation: conversation, account: account, inbox: inbox, content: "Oi ##{click.token}")

      described_class.attribute!(conversation, "Oi ##{click.token}")

      expect(conversation.reload.additional_attributes).to be_blank
      expect(click.reload.conversation_id).to be_nil
      expect(tracked_link.reload.conversations_count).to eq(0)
    end

    it 'does not increment the counter when a claimed click is deduped' do
      create(:message, conversation: conversation, account: account, inbox: inbox, content: "Oi ##{click.token}")
      conversation.update!(
        additional_attributes: {
          'campaign' => Ctwa::CampaignBuilder.build(
            source_id: "click:#{click.token}",
            source_type: 'bridge',
            headline: 'QR Loja',
            gclid: 'gclid-123'
          ),
          'campaign_touches' => [
            {
              'source' => 'google_ads',
              'source_id' => "click:#{click.token}",
              'source_type' => 'bridge',
              'headline' => 'QR Loja',
              'gclid' => 'gclid-123',
              'touched_at' => Time.current.utc.iso8601
            }
          ],
          'campaign_source_ids' => ["click:#{click.token}"]
        }
      )

      described_class.attribute!(conversation, "Oi ##{click.token}")

      expect(click.reload.conversation_id).to eq(conversation.id)
      expect(tracked_link.reload.conversations_count).to eq(0)
    end

    it 'does not attribute an expired click token' do
      click.update!(expires_at: 1.minute.ago)
      create(:message, conversation: conversation, account: account, inbox: inbox, content: "Oi ##{click.token}")

      described_class.attribute!(conversation, "Oi ##{click.token}")

      expect(conversation.reload.additional_attributes).to be_blank
      expect(click.reload.conversation_id).to be_nil
      expect(tracked_link.reload.conversations_count).to eq(0)
    end

    it 'infers attribution from a single active click in the same inbox within the fallback window' do
      click
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi')

      described_class.attribute!(conversation, 'Oi')

      attrs = conversation.reload.additional_attributes
      expect(attrs['campaign']).to include(
        'source' => 'google_ads',
        'source_id' => "click:#{click.token}",
        'source_type' => 'bridge',
        'inferred' => true
      )
      expect(attrs['campaign_touches'].first).to include('inferred' => true)
      expect(click.reload.conversation_id).to eq(conversation.id)
      expect(tracked_link.reload.conversations_count).to eq(1)
    end

    it 'does not query fallback clicks for a conversation created outside the inferred window' do
      conversation.update!(created_at: 11.minutes.ago)
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi')

      expect(Ctwa::TrackedLinkClick).not_to receive(:active)

      described_class.attribute!(conversation, 'Oi')

      expect(conversation.reload.additional_attributes).to be_blank
    end

    it 'does not infer attribution when the only click is outside the fallback window' do
      travel_to(11.minutes.ago) { click }
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi')

      described_class.attribute!(conversation, 'Oi')

      expect(conversation.reload.additional_attributes).to be_blank
      expect(click.reload.conversation_id).to be_nil
      expect(tracked_link.reload.conversations_count).to eq(0)
    end

    it 'does not infer attribution when there are multiple fallback candidates' do
      click
      create(:ctwa_tracked_link_click, account: account, tracked_link: tracked_link, token: 'WXYZ6789', params: { 'gclid' => 'other' })
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Oi')

      described_class.attribute!(conversation, 'Oi')

      expect(conversation.reload.additional_attributes).to be_blank
      expect(Ctwa::TrackedLinkClick.where(conversation_id: conversation.id)).to be_empty
      expect(tracked_link.reload.conversations_count).to eq(0)
    end
  end
end
