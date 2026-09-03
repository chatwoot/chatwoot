require 'rails_helper'

describe Line::SendOnLineService do
  describe '#perform' do
    let(:line_client) { double }
    let(:line_channel) { create(:channel_line) }
    let(:message) do
      create(:message, message_type: :outgoing, content: 'test',
                       conversation: create(:conversation, inbox: line_channel.inbox))
    end

    before do
      allow(Line::Bot::Client).to receive(:new).and_return(line_client)
    end

    context 'when message send' do
      it 'calls @channel.client.push_message' do
        allow(line_client).to receive(:push_message)
        expect(line_client).to receive(:push_message)
        described_class.new(message: message).perform
      end
    end

    context 'when message send fails without details' do
      let(:error_response) do
        {
          'message' => 'The request was invalid'
        }.to_json
      end

      before do
        allow(line_client).to receive(:push_message).and_return(OpenStruct.new(code: '400', body: error_response))
      end

      it 'updates the message status to failed' do
        described_class.new(message: message).perform
        message.reload
        expect(message.status).to eq('failed')
      end

      it 'updates the external error without details' do
        described_class.new(message: message).perform
        message.reload
        expect(message.external_error).to eq('The request was invalid')
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
        allow(line_client).to receive(:push_message).and_return(OpenStruct.new(code: '400', body: error_response))
      end

      it 'updates the message status to failed' do
        described_class.new(message: message).perform
        message.reload
        expect(message.status).to eq('failed')
      end

      it 'updates the external error with details' do
        described_class.new(message: message).perform
        message.reload
        expect(message.external_error).to eq('The request was invalid, messages[0].text: May not be empty')
      end
    end

    context 'when message send succeeds' do
      let(:success_response) do
        {
          'message' => 'ok'
        }.to_json
      end

      before do
        allow(line_client).to receive(:push_message).and_return(OpenStruct.new(code: '200', body: success_response))
      end

      it 'updates the message status to delivered' do
        described_class.new(message: message).perform
        message.reload
        expect(message.status).to eq('delivered')
      end
    end

    context 'with message input_select' do
      let(:success_response) do
        {
          'message' => 'ok'
        }.to_json
      end

      let(:expect_message) do
        {
          type: 'flex',
          altText: 'test',
          contents: {
            type: 'bubble',
            body: {
              type: 'box',
              layout: 'vertical',
              contents: [
                {
                  type: 'text',
                  text: 'test',
                  wrap: true
                },
                {
                  type: 'button',
                  style: 'link',
                  height: 'sm',
                  action: {
                    type: 'message',
                    label: 'text 1',
                    text: 'value 1'
                  }
                },
                {
                  type: 'button',
                  style: 'link',
                  height: 'sm',
                  action: {
                    type: 'message',
                    label: 'text 2',
                    text: 'value 2'
                  }
                }
              ]
            }
          }
        }
      end

      it 'sends the message with input_select' do
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                    content_attributes: { 'items' => [{ 'title' => 'text 1', 'value' => 'value 1' }, { 'title' => 'text 2', 'value' => 'value 2' }] },
                    conversation: create(:conversation, inbox: line_channel.inbox)
        )

        expect(line_client).to receive(:push_message).with(
          message.conversation.contact_inbox.source_id,
          expect_message
        ).and_return(OpenStruct.new(code: '200', body: success_response))

        described_class.new(message: message).perform
      end
    end

    context 'with message attachments' do
      it 'sends the message with text and attachments' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!
        expected_original_url_regex = %r{rails/active_storage/blobs/redirect/[a-zA-Z0-9=_\-+]+/avatar\.png}
        expected_preview_url_regex = %r{rails/active_storage/representations/redirect/[a-zA-Z0-9=_\-+]+/[a-zA-Z0-9=_\-+]+/avatar\.png}

        expect(line_client).to receive(:push_message).with(
          message.conversation.contact_inbox.source_id,
          [
            { type: 'text', text: message.content },
            {
              type: 'image',
              originalContentUrl: match(expected_original_url_regex),
              previewImageUrl: match(expected_preview_url_regex)
            }
          ]
        )

        described_class.new(message: message).perform
      end

      it 'sends the message with attachments only' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!
        message.update!(content: nil)
        expected_original_url_regex = %r{rails/active_storage/blobs/redirect/[a-zA-Z0-9=_\-+]+/avatar\.png}
        expected_preview_url_regex = %r{rails/active_storage/representations/redirect/[a-zA-Z0-9=_\-+]+/[a-zA-Z0-9=_\-+]+/avatar\.png}

        expect(line_client).to receive(:push_message).with(
          message.conversation.contact_inbox.source_id,
          [
            {
              type: 'image',
              originalContentUrl: match(expected_original_url_regex),
              previewImageUrl: match(expected_preview_url_regex)
            }
          ]
        )

        described_class.new(message: message).perform
      end

      it 'sends the message with text only' do
        message.attachments.destroy_all
        expect(line_client).to receive(:push_message).with(
          message.conversation.contact_inbox.source_id,
          { type: 'text', text: message.content }
        )

        described_class.new(message: message).perform
      end
    end
    context 'when the message carries a LINE Flex container' do
      let(:bubble) do
        {
          'type' => 'bubble',
          'hero' => { 'type' => 'image', 'url' => 'https://example.com/hero.jpg' },
          'footer' => {
            'type' => 'box', 'layout' => 'vertical',
            'contents' => [
              { 'type' => 'button', 'style' => 'primary',
                'action' => { 'type' => 'uri', 'label' => 'Open', 'uri' => 'https://example.com/form' } }
            ]
          }
        }
      end
      let(:flex_message) do
        create(:message, message_type: :outgoing, content: 'Report a problem',
                         content_attributes: { 'line_flex' => bubble },
                         conversation: create(:conversation, inbox: line_channel.inbox))
      end

      before { allow(line_client).to receive(:push_message) }

      it 'sends it through untouched' do
        expect(line_client).to receive(:push_message).with(
          anything, hash_including(type: 'flex', contents: bubble)
        )
        described_class.new(message: flex_message).perform
      end

      it 'uses the message content as altText' do
        expect(line_client).to receive(:push_message).with(
          anything, hash_including(altText: 'Report a problem')
        )
        described_class.new(message: flex_message).perform
      end

      it 'truncates altText to the 400 characters LINE allows' do
        flex_message.update!(content: 'a' * 500)
        expect(line_client).to receive(:push_message) do |_to, payload|
          expect(payload[:altText].length).to eq(400)
        end
        described_class.new(message: flex_message).perform
      end

      it 'never sends a blank altText' do
        flex_message.update!(content: '')
        expect(line_client).to receive(:push_message) do |_to, payload|
          expect(payload[:altText]).to be_present
        end
        described_class.new(message: flex_message).perform
      end

      it 'accepts a carousel as well as a bubble' do
        flex_message.update!(content_attributes: { 'line_flex' => { 'type' => 'carousel', 'contents' => [bubble] } })
        expect(line_client).to receive(:push_message).with(
          anything, hash_including(type: 'flex')
        )
        described_class.new(message: flex_message).perform
      end
    end

    context 'when line_flex is present but not a usable container' do
      before { allow(line_client).to receive(:push_message) }

      # Falling back keeps a malformed attribute from turning every reply into a
      # LINE 400. The text the agent wrote still reaches the customer.
      it 'falls back to text when the type is not bubble or carousel' do
        bad = create(:message, message_type: :outgoing, content: 'plain text',
                               content_attributes: { 'line_flex' => { 'type' => 'box' } },
                               conversation: create(:conversation, inbox: line_channel.inbox))
        expect(line_client).to receive(:push_message).with(anything, hash_including(type: 'text'))
        described_class.new(message: bad).perform
      end

      it 'falls back to text when it is not a hash' do
        bad = create(:message, message_type: :outgoing, content: 'plain text',
                               content_attributes: { 'line_flex' => 'bubble' },
                               conversation: create(:conversation, inbox: line_channel.inbox))
        expect(line_client).to receive(:push_message).with(anything, hash_including(type: 'text'))
        described_class.new(message: bad).perform
      end
    end

    context 'when no Flex container is supplied' do
      before { allow(line_client).to receive(:push_message) }

      # Guards the existing behaviour: every message that worked before must
      # still take the same path.
      it 'still sends a plain text message' do
        expect(line_client).to receive(:push_message).with(anything, hash_including(type: 'text'))
        described_class.new(message: message).perform
      end
    end

  end
end
