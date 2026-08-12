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

  context 'when a WhatsApp carousel item uses the postback/link legacy aliases and has no title' do
    it 'is invalid' do
      message = build_card_message(
        [
          { description: 'desc', actions: [{ type: 'postback', text: 'Go', payload: 'p1' }] },
          { title: 'Card 2', actions: [{ type: 'postback', text: 'Go', payload: 'p2' }] }
        ]
      )

      expect(message).to be_invalid
      expect(message.errors[:content_attributes]).to include('contains items missing title')
    end
  end

  context 'when a WhatsApp carousel has more than 10 cards' do
    it 'is invalid' do
      items = (1..11).map do |i|
        { title: "Card #{i}", actions: [{ type: 'reply', text: 'Go', payload: "p#{i}" }] }
      end
      message = build_card_message(items)

      expect(message).to be_invalid
      expect(message.errors[:content_attributes]).to include('interactive carousel messages support at most 10 cards')
    end
  end

  context 'when a WhatsApp carousel has exactly 10 cards' do
    it 'is valid' do
      items = (1..10).map do |i|
        { title: "Card #{i}", actions: [{ type: 'reply', text: 'Go', payload: "p#{i}" }] }
      end
      message = build_card_message(items)

      expect(message).to be_valid
    end
  end

  context 'when a WhatsApp carousel mixes url and reply cards across cards' do
    it 'is invalid' do
      message = build_card_message(
        [
          { title: 'Card 1', actions: [{ type: 'url', text: 'Visit', uri: 'https://example.com' }] },
          { title: 'Card 2', actions: [{ type: 'reply', text: 'Select', payload: 'p2' }] }
        ]
      )

      expect(message).to be_invalid
      expect(message.errors[:content_attributes]).to include('contains carousel cards with mixed action types across cards')
    end
  end

  context 'when a WhatsApp carousel cards have the same action type but different action counts' do
    it 'is invalid' do
      message = build_card_message(
        [
          { title: 'Card 1', actions: [{ type: 'reply', text: 'Go', payload: 'p1' }] },
          { title: 'Card 2', actions: [{ type: 'reply', text: 'A', payload: 'p2a' }, { type: 'reply', text: 'B', payload: 'p2b' }] }
        ]
      )

      expect(message).to be_invalid
      expect(message.errors[:content_attributes]).to include('contains carousel cards with mixed action types across cards')
    end
  end

  context 'when a WhatsApp carousel uses the same action type across all cards' do
    it 'is valid' do
      message = build_card_message(
        [
          { title: 'Card 1', actions: [{ type: 'url', text: 'Visit', uri: 'https://example.com/1' }] },
          { title: 'Card 2', actions: [{ type: 'url', text: 'Visit', uri: 'https://example.com/2' }] }
        ]
      )

      expect(message).to be_valid
    end
  end

  context 'when a non-Meta cards message item has no title' do
    it 'is valid' do
      widget_channel = create(:channel_widget, account: account)
      widget_inbox = create(:inbox, channel: widget_channel, account: account)
      widget_conversation = create(:conversation, account: account, inbox: widget_inbox)

      message = build(:message, conversation: widget_conversation, account: account, inbox: widget_inbox,
                                message_type: :outgoing, content_type: 'cards',
                                content_attributes: {
                                  items: [{
                                    description: 'desc', media_url: 'https://example.com/img.jpg',
                                    actions: [{ type: 'reply', text: 'Go', payload: 'p1' }]
                                  }]
                                })

      expect(message).to be_valid
    end
  end

  context 'when a cta_url message has an attachment' do
    it 'is invalid' do
      message = build(:message, conversation: conversation, account: account, inbox: whatsapp_inbox,
                                message_type: :outgoing, content_type: 'cta_url',
                                content_attributes: {
                                  body_text: 'Check our website',
                                  action: { text: 'Visit', uri: 'https://example.com' }
                                })
      attachment = message.attachments.new(account_id: account.id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

      expect(message).to be_invalid
      expect(message.errors[:content_attributes]).to include('cta_url messages do not support attachments')
    end
  end

  context 'when a non-Meta cards message has an attachment' do
    it 'is valid' do
      widget_channel = create(:channel_widget, account: account)
      widget_inbox = create(:inbox, channel: widget_channel, account: account)
      widget_conversation = create(:conversation, account: account, inbox: widget_inbox)

      message = build(:message, conversation: widget_conversation, account: account, inbox: widget_inbox,
                                message_type: :outgoing, content_type: 'cards',
                                content_attributes: {
                                  items: [{
                                    title: 'Card 1', media_url: 'https://example.com/img.jpg',
                                    actions: [{ type: 'reply', text: 'Go', payload: 'p1' }]
                                  }]
                                })
      attachment = message.attachments.new(account_id: account.id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

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
