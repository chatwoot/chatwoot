require 'rails_helper'

describe ContentAttributeValidator do
  let!(:account) { create(:account) }
  let!(:whatsapp_channel) { create(:channel_whatsapp, account: account, validate_provider_config: false, sync_templates: false) }
  let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }

  def build_card_message(items)
    build(:message, conversation: conversation, account: account, inbox: whatsapp_inbox,
                    message_type: :outgoing, content_type: 'cards',
                    content_attributes: { items: items })
  end

  context 'when a cards message item has valid actions but no title' do
    it 'is invalid' do
      message = build_card_message(
        [{ description: 'desc', actions: [{ type: 'reply', text: 'Go', payload: 'p1' }] }]
      )

      expect(message).to be_invalid
      expect(message.errors[:content_attributes]).to include('contains items missing title')
    end
  end

  context 'when every cards message item has a title' do
    it 'is valid' do
      message = build_card_message(
        [
          { title: 'Card 1', description: 'desc', actions: [{ type: 'reply', text: 'Go', payload: 'p1' }] },
          { title: 'Card 2', description: 'desc', actions: [{ type: 'reply', text: 'Go', payload: 'p2' }] }
        ]
      )

      expect(message).to be_valid
    end
  end
end
