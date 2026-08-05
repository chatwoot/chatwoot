require 'rails_helper'

describe Instagram::SendOnInstagramService do
  subject(:send_reply_service) { described_class.new(message: message) }

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram, account: account, instagram_id: 'instagram-message-id-123') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }

  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: instagram_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: instagram_inbox, contact_inbox: contact_inbox) }
  let(:response) { double }
  let(:mock_response) do
    instance_double(
      HTTParty::Response,
      :success? => true,
      :body => { message_id: 'random_message_id' }.to_json,
      :parsed_response => { 'message_id' => 'random_message_id' }
    )
  end

  let(:error_body) do
    {
      'error' => {
        'message' => 'The Instagram account is restricted.',
        'type' => 'OAuthException',
        'code' => 400,
        'fbtrace_id' => 'anyrandomfbtraceid1234567890'
      }
    }
  end

  let(:error_response) do
    instance_double(
      HTTParty::Response,
      :success? => false,
      :body => error_body.to_json,
      :parsed_response => error_body
    )
  end

  let(:response_with_error) do
    instance_double(
      HTTParty::Response,
      :success? => true,
      :body => error_body.to_json,
      :parsed_response => error_body
    )
  end

  describe '#perform' do
    context 'with reply' do
      before do
        allow(HTTParty).to receive(:post).and_return(mock_response)
      end

      context 'without message_tag HUMAN_AGENT' do
        before do
          InstallationConfig.where(name: 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT').first_or_create(value: false)
        end

        it 'if message is sent from chatwoot and is outgoing' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          response = described_class.new(message: message).perform
          expect(response['message_id']).to eq('random_message_id')
        end

        it 'if message is sent from chatwoot and is outgoing with multiple attachments' do
          message = build(:message, content: nil, message_type: 'outgoing', inbox: instagram_inbox, account: account,
                                    conversation: conversation)
          avatar = message.attachments.new(account_id: message.account_id, file_type: :image)
          avatar.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
          sample = message.attachments.new(account_id: message.account_id, file_type: :image)
          sample.file.attach(io: Rails.root.join('spec/assets/sample.png').open, filename: 'sample.png', content_type: 'image/png')
          message.save!

          service = described_class.new(message: message)

          # Stub the send_message method on the service instance
          allow(service).to receive(:send_message)
          service.perform

          # Now you can set expectations on the stubbed method for each attachment
          expect(service).to have_received(:send_message).exactly(:twice)
        end

        it 'if message with attachment is sent from chatwoot and is outgoing' do
          message = build(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)
          attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
          attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
          message.save!
          response = described_class.new(message: message).perform

          expect(response['message_id']).to eq('random_message_id')
        end

        it 'if message sent from chatwoot is failed' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          allow(HTTParty).to receive(:post).and_return(response_with_error)
          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post)
          expect(message.reload.status).to eq('failed')
          expect(message.reload.external_error).to eq('400 - The Instagram account is restricted.')
        end
      end

      context 'with message_tag HUMAN_AGENT' do
        before do
          InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').first_or_create(value: true)
        end

        it 'if message is sent from chatwoot and is outgoing' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          allow(HTTParty).to receive(:post).with(
            {
              recipient: { id: contact.get_source_id(instagram_inbox.id) },
              message: {
                text: message.content
              },
              messaging_type: 'MESSAGE_TAG',
              tag: 'HUMAN_AGENT'
            }
          ).and_return(
            {
              'message_id': 'random_message_id'
            }
          )

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post)
        end
      end

      context 'when handling errors' do
        it 'handles HTTP errors' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)
          allow(HTTParty).to receive(:post).and_return(error_response)

          described_class.new(message: message).perform

          expect(message.reload.status).to eq('failed')
          expect(message.reload.external_error).to eq('400 - The Instagram account is restricted.')
        end

        it 'handles response errors' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          error_response = instance_double(
            HTTParty::Response,
            success?: true,
            body: { 'error' => { 'message' => 'Invalid message format', 'code' => 100 } }.to_json,
            parsed_response: { 'error' => { 'message' => 'Invalid message format', 'code' => 100 } }
          )

          allow(HTTParty).to receive(:post).and_return(error_response)

          described_class.new(message: message).perform

          expect(message.reload.status).to eq('failed')
          expect(message.reload.external_error).to eq('100 - Invalid message format')
        end

        it 'handles reauthorization errors if access token is expired' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation)

          error_response = instance_double(
            HTTParty::Response,
            success?: false,
            body: { 'error' => { 'message' => 'Access token has expired', 'code' => 190 } }.to_json,
            parsed_response: { 'error' => { 'message' => 'Access token has expired', 'code' => 190 } }
          )

          allow(HTTParty).to receive(:post).and_return(error_response)

          described_class.new(message: message).perform

          expect(message.reload.status).to eq('failed')
          expect(message.reload.external_error).to eq('190 - Access token has expired')
          expect(instagram_channel.reload).to be_reauthorization_required
        end
      end

      context 'with cards (generic template)' do
        it 'sends generic template message for cards content type' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation,
                                     content_type: 'cards',
                                     content_attributes: {
                                       'items' => [
                                         {
                                           'title' => 'Card 1',
                                           'description' => 'Description 1',
                                           'media_url' => 'https://example.com/img1.jpg',
                                           'actions' => [
                                             { 'type' => 'url', 'text' => 'Visit', 'uri' => 'https://example.com' }
                                           ]
                                         }
                                       ]
                                     })

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post).with(
            anything,
            hash_including(
              body: a_string_including('"template_type":"generic"'),
              headers: { 'Content-Type' => 'application/json' }
            )
          )
        end
      end

      context 'with cards intro text (multi-part send)' do
        it 'preserves the intro text MID so its inbound echo is not duplicated' do
          allow(HTTParty).to receive(:post).and_return(
            instance_double(HTTParty::Response, success?: true, body: { message_id: 'mid_intro' }.to_json,
                                                parsed_response: { 'message_id' => 'mid_intro' }),
            instance_double(HTTParty::Response, success?: true, body: { message_id: 'mid_generic' }.to_json,
                                                parsed_response: { 'message_id' => 'mid_generic' })
          )

          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation,
                                     content: 'Check these out',
                                     content_type: 'cards',
                                     content_attributes: {
                                       'items' => [
                                         {
                                           'title' => 'Card 1',
                                           'actions' => [{ 'type' => 'url', 'text' => 'Visit', 'uri' => 'https://example.com' }]
                                         }
                                       ]
                                     })

          described_class.new(message: message).perform

          expect(message.reload.source_id).to eq('mid_generic')
          expect(message.content_attributes['additional_source_ids']).to eq(['mid_intro'])
        end
      end

      context 'with cards body text longer than the Messenger title limit' do
        it 'truncates the generic-template title and subtitle to 80 characters' do
          long_title = 'T' * 200
          long_description = 'D' * 200
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation,
                                     content_type: 'cards',
                                     content_attributes: {
                                       'items' => [
                                         {
                                           'title' => long_title,
                                           'description' => long_description,
                                           'actions' => [{ 'type' => 'url', 'text' => 'Visit', 'uri' => 'https://example.com' }]
                                         }
                                       ]
                                     })

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post).with(
            anything,
            hash_including(
              body: a_string_including("\"title\":\"#{'T' * 80}\"", "\"subtitle\":\"#{'D' * 80}\"")
            )
          )
        end
      end

      context 'with interactive_buttons' do
        it 'sends button template message for interactive_buttons content type' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation,
                                     content_type: 'interactive_buttons',
                                     content: 'Choose an option',
                                     content_attributes: {
                                       'body_text' => 'Please select:',
                                       'buttons' => [
                                         { 'id' => 'btn_1', 'text' => 'Option A', 'type' => 'reply' },
                                         { 'id' => 'btn_2', 'text' => 'Option B', 'type' => 'reply' }
                                       ]
                                     })

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post).with(
            anything,
            hash_including(
              body: a_string_including('"template_type":"button"'),
              headers: { 'Content-Type' => 'application/json' }
            )
          )
        end
      end

      context 'with cta_url body text longer than the Messenger title limit' do
        it 'truncates the generic-template title to 80 characters' do
          long_body = 'B' * 200
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation,
                                     content_type: 'cta_url', content: long_body,
                                     content_attributes: {
                                       'body_text' => long_body,
                                       'action' => { 'text' => 'Visit Now', 'uri' => 'https://example.com' }
                                     })

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post).with(
            anything,
            hash_including(
              body: a_string_including("\"title\":\"#{'B' * 80}\"")
            )
          )
        end
      end

      context 'with cta_url' do
        it 'sends CTA URL generic template message for cta_url content type' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation,
                                     content_type: 'cta_url',
                                     content: 'Visit our site',
                                     content_attributes: {
                                       'body_text' => 'Check our website',
                                       'action' => { 'text' => 'Visit Now', 'uri' => 'https://example.com' }
                                     })

          described_class.new(message: message).perform
          expect(HTTParty).to have_received(:post).with(
            anything,
            hash_including(
              body: a_string_including('"template_type":"generic"'),
              headers: { 'Content-Type' => 'application/json' }
            )
          )
        end
      end
    end
  end
end
