require 'rails_helper'

RSpec.describe Line::SendOnLineService do
  describe '#perform' do
    let(:messaging_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }
    let(:line_channel) { create(:channel_line) }
    let(:message) do
      create(
        :message,
        message_type: :outgoing,
        content: 'test',
        conversation: create(:conversation, inbox: line_channel.inbox)
      )
    end

    before do
      allow(line_channel).to receive(:messaging_api_client).and_return(messaging_client)
      allow(messaging_client).to receive(:push_message_with_http_info).and_return([{}, 200, {}])
    end

    context 'when message carries LINE notification template params' do
      let(:message) do
        create(
          :message,
          message_type: :outgoing,
          content: 'test',
          additional_attributes: {
            'template_params' => {
              'name' => 'line-notification',
              'type' => 'flexible',
              'messages' => [
                { 'type' => 'text', 'text' => 'hello from notification' }
              ],
              'phone_number' => '+1 (415) 555-2671'
            }
          },
          conversation: create(:conversation, inbox: line_channel.inbox)
        )
      end

      it 'routes to the notification message service' do
        notification_service = instance_double(Line::NotificationMessageService)
        allow(Line::NotificationMessageService).to receive(:new).and_return(notification_service)
        allow(notification_service).to receive(:perform)

        described_class.new(message: message).perform

        expect(Line::NotificationMessageService).to have_received(:new).with(message: message)
        expect(notification_service).to have_received(:perform)
        expect(messaging_client).not_to have_received(:push_message_with_http_info)
      end
    end

    context 'when template params are not a LINE notification payload' do
      let(:message) do
        create(
          :message,
          message_type: :outgoing,
          content: 'test',
          additional_attributes: {
            'template_params' => {
              'name' => 'line-notification',
              'foo' => 'bar'
            }
          },
          conversation: create(:conversation, inbox: line_channel.inbox)
        )
      end

      it 'uses the regular send path' do
        described_class.new(message: message).perform

        expect(messaging_client).to have_received(:push_message_with_http_info) do |push_message_request:|
          expect(push_message_request.messages.first.text).to eq('test')
        end
      end
    end

    context 'when template params include only a type without notification fields' do
      let(:message) do
        create(
          :message,
          message_type: :outgoing,
          content: 'test',
          additional_attributes: {
            'template_params' => {
              'name' => 'line-notification',
              'type' => 'template'
            }
          },
          conversation: create(:conversation, inbox: line_channel.inbox)
        )
      end

      it 'uses the regular send path' do
        described_class.new(message: message).perform

        expect(messaging_client).to have_received(:push_message_with_http_info)
      end
    end

    context 'when message send' do
      it 'pushes a v2 request object to the contact inbox source id' do
        described_class.new(message: message).perform

        expect(messaging_client).to have_received(:push_message_with_http_info) do |push_message_request:|
          expect(push_message_request).to be_a(Line::Bot::V2::MessagingApi::PushMessageRequest)
          expect(push_message_request.to).to eq(message.conversation.contact_inbox.source_id)
          expect(push_message_request.messages.first.text).to eq('test')
        end
      end
    end

    context 'when message send fails without details' do
      let(:error_response) do
        {
          'message' => 'The request was invalid'
        }.to_json
      end

      before do
        allow(messaging_client).to receive(:push_message_with_http_info).and_return([error_response, 400, {}])
      end

      it 'updates the message status to failed' do
        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
      end

      it 'updates the external error without details' do
        described_class.new(message: message).perform

        expect(message.reload.external_error).to eq('The request was invalid')
      end
    end

    context 'when message send fails with details' do
      let(:error_response) do
        {
          'message' => 'The request was invalid',
          'details' => [
            {
              'property' => 'messages[0].text',
              'message' => 'May not be empty'
            }
          ]
        }.to_json
      end

      before do
        allow(messaging_client).to receive(:push_message_with_http_info).and_return([error_response, 400, {}])
      end

      it 'updates the message status to failed' do
        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
      end

      it 'updates the external error with details' do
        described_class.new(message: message).perform

        expect(message.reload.external_error).to eq('The request was invalid, messages[0].text: May not be empty')
      end
    end

    context 'when message send fails with SDK error object' do
      let(:error_response) do
        Line::Bot::V2::MessagingApi::ErrorResponse.new(
          message: 'The request was invalid',
          details: [
            Line::Bot::V2::MessagingApi::ErrorDetail.new(
              property: 'messages[0].text',
              message: 'May not be empty'
            )
          ]
        )
      end

      before do
        allow(messaging_client).to receive(:push_message_with_http_info).and_return([error_response, 400, {}])
      end

      it 'updates the message status to failed' do
        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
      end

      it 'updates the external error from the SDK error object' do
        described_class.new(message: message).perform

        expect(message.reload.external_error).to eq('The request was invalid, messages[0].text: May not be empty')
      end
    end

    context 'when message send succeeds' do
      it 'updates the message status to delivered' do
        described_class.new(message: message).perform

        expect(message.reload.status).to eq('delivered')
      end
    end

    context 'with message input_select' do
      it 'sends the message with input_select' do
        input_select_message = create(
          :message,
          message_type: :outgoing,
          content: 'test',
          content_type: 'input_select',
          content_attributes: {
            'items' => [
              { 'title' => 'text 1', 'value' => 'value 1' },
              { 'title' => 'text 2', 'value' => 'value 2' }
            ]
          },
          conversation: create(:conversation, inbox: line_channel.inbox)
        )

        described_class.new(message: input_select_message).perform

        expect(messaging_client).to have_received(:push_message_with_http_info) do |push_message_request:|
          flex_message = push_message_request.messages.first
          buttons = flex_message.contents.body.contents.drop(1)

          aggregate_failures do
            expect(flex_message).to be_a(Line::Bot::V2::MessagingApi::FlexMessage)
            expect(flex_message.alt_text).to eq('test')
            expect(flex_message.contents.body.contents.first.text).to eq('test')
            expect(buttons.map { |button| [button.action.label, button.action.text] }).to eq(
              [['text 1', 'value 1'], ['text 2', 'value 2']]
            )
          end
        end
      end
    end

    context 'with message attachments' do
      it 'sends the message with text and attachments' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!
        expected_original_url_regex = %r{rails/active_storage/blobs/redirect/[a-zA-Z0-9=_\-+]+/avatar\.png}
        expected_preview_url_regex = %r{rails/active_storage/representations/redirect/[a-zA-Z0-9=_\-+]+/[a-zA-Z0-9=_\-+]+/avatar\.png}

        described_class.new(message: message).perform

        expect(messaging_client).to have_received(:push_message_with_http_info) do |push_message_request:|
          expect(push_message_request.messages.first.text).to eq(message.content)

          image_message = push_message_request.messages.second
          expect(image_message).to be_a(Line::Bot::V2::MessagingApi::ImageMessage)
          expect(image_message.original_content_url).to match(expected_original_url_regex)
          expect(image_message.preview_image_url).to match(expected_preview_url_regex)
        end
      end

      it 'sends the message with attachments only' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!
        message.update!(content: nil)
        expected_original_url_regex = %r{rails/active_storage/blobs/redirect/[a-zA-Z0-9=_\-+]+/avatar\.png}
        expected_preview_url_regex = %r{rails/active_storage/representations/redirect/[a-zA-Z0-9=_\-+]+/[a-zA-Z0-9=_\-+]+/avatar\.png}

        described_class.new(message: message).perform

        expect(messaging_client).to have_received(:push_message_with_http_info) do |push_message_request:|
          image_message = push_message_request.messages.first
          expect(image_message).to be_a(Line::Bot::V2::MessagingApi::ImageMessage)
          expect(image_message.original_content_url).to match(expected_original_url_regex)
          expect(image_message.preview_image_url).to match(expected_preview_url_regex)
        end
      end

      it 'sends the message with text only' do
        message.attachments.destroy_all

        described_class.new(message: message).perform

        expect(messaging_client).to have_received(:push_message_with_http_info) do |push_message_request:|
          expect(push_message_request.messages.first.text).to eq(message.content)
        end
      end
    end
  end
end
