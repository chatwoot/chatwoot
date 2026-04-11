require 'rails_helper'

RSpec.describe Line::NotificationMessageService do
  describe '#perform' do
    let(:line_channel) { create(:channel_line) }
    let(:messaging_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }
    let(:notification_http_client) { instance_double(Line::Bot::V2::HttpClient) }
    let(:contact) { create(:contact, account: line_channel.account) }
    let(:conversation) { create(:conversation, inbox: line_channel.inbox, contact: contact) }
    let(:normalized_phone_number) { '+14155552671' }
    let(:hashed_phone_number) { Digest::SHA256.hexdigest(normalized_phone_number) }
    let(:delivery_tag) { "chatwoot-line-pnp-#{message.id}" }
    let(:template_params) do
      {
        'name' => 'line-notification',
        'type' => 'flexible',
        'phone_number' => '+1 (415) 555-2671',
        'messages' => [
          { 'type' => 'text', 'text' => 'hello from notification' }
        ]
      }
    end
    let(:message) do
      create(
        :message,
        message_type: :outgoing,
        content: 'test',
        conversation: conversation,
        additional_attributes: { 'template_params' => template_params }
      )
    end

    before do
      allow(line_channel).to receive(:messaging_api_client).and_return(messaging_client)
      allow(line_channel).to receive(:notification_message_http_client).and_return(notification_http_client)
    end

    context 'when sending a flexible notification message' do
      before do
        allow(messaging_client).to receive(:push_messages_by_phone_with_http_info).and_return([{}, 200, { 'x-line-request-id' => 'request-123' }])
      end

      it 'hashes the phone number, persists the delivery tag, and keeps the message sent' do
        described_class.new(message: message).perform

        expect(messaging_client).to have_received(:push_messages_by_phone_with_http_info) do |pnp_messages_request:, x_line_delivery_tag:|
          expect(pnp_messages_request).to be_a(Line::Bot::V2::MessagingApi::PnpMessagesRequest)
          expect(pnp_messages_request.to).to eq(hashed_phone_number)
          expect(pnp_messages_request.messages.first).to be_a(Line::Bot::V2::MessagingApi::TextMessage)
          expect(pnp_messages_request.messages.first.text).to eq('hello from notification')
          expect(x_line_delivery_tag).to eq(delivery_tag)
        end

        message.reload
        aggregate_failures do
          expect(message.status).to eq('sent')
          expect(message.source_id).to eq('request-123')
          expect(message.additional_attributes['template_params']['type']).to eq('flexible')
          expect(message.additional_attributes['template_params']['phone_number']).to eq(normalized_phone_number)
          expect(message.additional_attributes['template_params']['phone_number_sha256']).to eq(hashed_phone_number)
          expect(message.additional_attributes['template_params']['delivery_tag']).to eq(delivery_tag)
          expect(message.additional_attributes['template_params']['x_line_request_id']).to eq('request-123')
        end
      end
    end

    context 'when sending a templated notification message' do
      let(:template_params) do
        {
          'name' => 'line-notification',
          'type' => 'template',
          'phone_number' => '+1 (415) 555-2671',
          'template_key' => 'order-confirmation',
          'notification_disabled' => true,
          'body' => {
            'title' => 'Order confirmation'
          }
        }
      end
      let(:response) { instance_double(Net::HTTPResponse, code: '202', body: '', each_header: { 'x-line-request-id' => 'request-456' }) }

      before do
        allow(notification_http_client).to receive(:post).and_return(response)
      end

      it 'posts to the templated notification endpoint and keeps the message sent' do
        described_class.new(message: message).perform

        expect(notification_http_client).to have_received(:post) do |args|
          expect(args[:path]).to eq('/v2/bot/message/pnp/templated/push')
          expect(args[:body_params]).to include(
            to: hashed_phone_number,
            template_key: 'order-confirmation',
            notification_disabled: true,
            body: {
              'title' => 'Order confirmation'
            }
          )
          expect(args[:headers]).to include('X-Line-Delivery-Tag' => delivery_tag)
        end

        message.reload
        aggregate_failures do
          expect(message.status).to eq('sent')
          expect(message.source_id).to eq('request-456')
          expect(message.additional_attributes['template_params']['phone_number_sha256']).to eq(hashed_phone_number)
          expect(message.additional_attributes['template_params']['delivery_tag']).to eq(delivery_tag)
          expect(message.additional_attributes['template_params']['x_line_request_id']).to eq('request-456')
        end
      end
    end

    context 'when attachments are present' do
      let(:template_params) do
        {
          'name' => 'line-notification',
          'type' => 'flexible',
          'messages' => [
            { 'type' => 'text', 'text' => 'hello from notification' }
          ]
        }
      end

      before do
        allow(messaging_client).to receive(:push_messages_by_phone_with_http_info)
        allow(notification_http_client).to receive(:post)

        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!
      end

      it 'marks the message as failed without calling LINE' do
        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'failed', /attachments/i).and_call_original

        described_class.new(message: message).perform

        expect(messaging_client).not_to have_received(:push_messages_by_phone_with_http_info)
        expect(notification_http_client).not_to have_received(:post)
        expect(message.reload.status).to eq('failed')
      end
    end

    context 'when no phone number can be resolved' do
      let(:template_params) do
        {
          'name' => 'line-notification',
          'type' => 'flexible',
          'messages' => [
            { 'type' => 'text', 'text' => 'hello from notification' }
          ]
        }
      end

      it 'marks the message as failed' do
        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to match(/phone number/i)
      end
    end
  end
end
