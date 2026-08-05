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

  def build_list_message(sections)
    build(:message, conversation: conversation, account: account, inbox: whatsapp_inbox,
                    message_type: :outgoing, content_type: 'interactive_list',
                    content_attributes: {
                      body_text: 'Pick an item',
                      action: { button_text: 'View options' },
                      sections: sections
                    })
  end

  context 'when an interactive_list has more than 10 rows across all sections' do
    it 'is invalid' do
      sections = (1..11).map { |i| { title: "Section #{i}", rows: [{ id: "row_#{i}", title: "Row #{i}" }] } }
      message = build_list_message(sections)

      expect(message).to be_invalid
      expect(message.errors[:content_attributes]).to include('interactive_list supports at most 10 rows across all sections')
    end
  end

  context 'when an interactive_list has exactly 10 rows across all sections' do
    it 'is valid' do
      sections = (1..10).map { |i| { title: "Section #{i}", rows: [{ id: "row_#{i}", title: "Row #{i}" }] } }
      message = build_list_message(sections)

      expect(message).to be_valid
    end
  end
end
