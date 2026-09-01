require 'rails_helper'

RSpec.describe Line::DeliveryStatusService do
  let!(:line_channel) { create(:channel_line) }
  let(:conversation) { create(:conversation, inbox: line_channel.inbox) }
  let(:message) do
    create(
      :message,
      message_type: :outgoing,
      status: 'sent',
      inbox: line_channel.inbox,
      conversation: conversation
    )
  end

  describe '#perform' do
    context 'when the delivery tag includes the chatwoot prefix' do
      let(:message_id) { 123_456 }
      let(:delivery_tag) { "chatwoot-line-pnp-#{message_id}" }
      let(:message) do
        create(
          :message,
          id: message_id,
          message_type: :outgoing,
          status: 'sent',
          inbox: line_channel.inbox,
          conversation: conversation,
          additional_attributes: {
            template_params: {
              name: 'line-template',
              delivery_tag: delivery_tag
            }
          }
        )
      end
      let(:params) do
        {
          'events' => [
            {
              'type' => 'delivery',
              'delivery' => { 'data' => delivery_tag }
            }
          ]
        }.with_indifferent_access
      end

      it 'marks the matching message as delivered' do
        message
        message_count = Message.count
        conversation_count = Conversation.count

        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'delivered').and_call_original

        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(Message.count).to eq(message_count)
        expect(Conversation.count).to eq(conversation_count)
        expect(message.reload.status).to eq('delivered')
      end
    end

    context 'when the prefixed lookup misses and fallback resolves from template params' do
      let(:delivery_tag) { 'chatwoot-line-pnp-999999' }
      let(:message) do
        create(
          :message,
          message_type: :outgoing,
          status: 'sent',
          inbox: line_channel.inbox,
          conversation: conversation,
          additional_attributes: {
            template_params: {
              name: 'line-template',
              delivery_tag: delivery_tag
            }
          }
        )
      end
      let(:params) do
        {
          'events' => [
            {
              'type' => 'delivery',
              'delivery' => { 'data' => delivery_tag }
            }
          ]
        }.with_indifferent_access
      end

      it 'marks the matching message as delivered' do
        message
        message_count = Message.count
        conversation_count = Conversation.count

        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'delivered').and_call_original

        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(Message.count).to eq(message_count)
        expect(Conversation.count).to eq(conversation_count)
        expect(message.reload.status).to eq('delivered')
      end
    end

    context 'when a prefixed tag points at an unrelated message id' do
      let!(:other_message) do
        create(
          :message,
          id: 999_999,
          message_type: :outgoing,
          status: 'sent',
          inbox: line_channel.inbox,
          conversation: conversation,
          additional_attributes: {
            template_params: {
              name: 'other-template',
              delivery_tag: 'chatwoot-line-pnp-123456'
            }
          }
        )
      end
      let(:delivery_tag) { 'chatwoot-line-pnp-999999' }
      let(:message) do
        create(
          :message,
          message_type: :outgoing,
          status: 'sent',
          inbox: line_channel.inbox,
          conversation: conversation,
          additional_attributes: {
            template_params: {
              name: 'line-template',
              delivery_tag: delivery_tag
            }
          }
        )
      end
      let(:params) do
        {
          'events' => [
            {
              'type' => 'delivery',
              'delivery' => { 'data' => delivery_tag }
            }
          ]
        }.with_indifferent_access
      end

      it 'falls back to the stored delivery tag instead of the unrelated message id' do
        message
        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'delivered').and_call_original
        expect(Messages::StatusUpdateService).not_to receive(:new).with(other_message, 'delivered')

        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(message.reload.status).to eq('delivered')
        expect(other_message.reload.status).to eq('sent')
      end
    end

    context 'when the delivery tag is malformed or unmatched' do
      let(:params) do
        {
          'events' => [
            {
              'type' => 'delivery',
              'delivery' => { 'data' => 'bad-delivery-tag' }
            }
          ]
        }.with_indifferent_access
      end

      it 'does nothing' do
        message_count = Message.count
        conversation_count = Conversation.count

        expect(Messages::StatusUpdateService).not_to receive(:new)

        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(Message.count).to eq(message_count)
        expect(Conversation.count).to eq(conversation_count)
        expect(message.reload.status).to eq('sent')
      end
    end

    context 'when the delivery tag uses the prefix but has no message id' do
      let(:params) do
        {
          'events' => [
            {
              'type' => 'delivery',
              'delivery' => { 'data' => 'chatwoot-line-pnp-' }
            }
          ]
        }.with_indifferent_access
      end

      it 'does nothing' do
        message
        message_count = Message.count
        conversation_count = Conversation.count

        expect(Messages::StatusUpdateService).not_to receive(:new)

        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(Message.count).to eq(message_count)
        expect(Conversation.count).to eq(conversation_count)
        expect(message.reload.status).to eq('sent')
      end
    end

    context 'when delivery data is blank' do
      let(:params) do
        {
          'events' => [
            {
              'type' => 'delivery',
              'delivery' => { 'data' => '' }
            }
          ]
        }.with_indifferent_access
      end

      it 'does nothing' do
        message
        message_count = Message.count
        conversation_count = Conversation.count

        expect(Messages::StatusUpdateService).not_to receive(:new)

        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(Message.count).to eq(message_count)
        expect(Conversation.count).to eq(conversation_count)
        expect(message.reload.status).to eq('sent')
      end
    end
  end
end
