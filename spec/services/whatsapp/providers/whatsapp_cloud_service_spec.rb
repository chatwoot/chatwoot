require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:business_management_token) { nil }
  let(:whatsapp_channel) do
    create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      business_management_token: business_management_token,
      validate_provider_config: false,
      sync_templates: false
    )
  end

  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox, source_id: 'external_id')
  end

  let(:message_with_reply) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'reply', inbox: whatsapp_channel.inbox,
                     content_attributes: { in_reply_to: message.id })
  end

  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }
  let(:media_upload_url) { 'https://graph.facebook.com/v22.0/123456789/media' }

  before do
    stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
    stub_request(:post, media_upload_url)
      .to_return(status: 200, body: { id: 'uploaded_media_id' }.to_json, headers: response_headers)
  end

  describe '#send_message' do
    context 'when called' do
      it 'calls message endpoints for normal messages' do
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              context: nil,
              to: '+123456789',
              text: { body: message.content },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'preserves HTML-like content in normal message requests' do
        message.update!(content: "<a>\n<b></b></a>asdf")

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              context: nil,
              to: '+123456789',
              text: { body: message.content },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for a reply to messages' do
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              context: {
                message_id: message.source_id
              },
              to: '+123456789',
              text: { body: message_with_reply.content },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message_with_reply)).to eq 'message_id'
      end

      it 'calls message endpoints for image attachment message messages' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'image',
                                   image: WebMock::API.hash_including({ caption: message.content, id: 'uploaded_media_id' })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for document attachment message messages' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.pdf').open, filename: 'sample.pdf', content_type: 'application/pdf')
        attachment.save!

        # ref: https://github.com/bblimke/webmock/issues/900
        # reason for Webmock::API.hash_including
        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'document',
                                   document: WebMock::API.hash_including({ filename: 'sample.pdf', caption: message.content,
                                                                           id: 'uploaded_media_id' })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for audio attachment message' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.mp3').open, filename: 'sample.mp3', content_type: 'audio/mpeg')

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'audio',
                                   audio: WebMock::API.hash_including({ link: anything })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for audio voice message with voice flag' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :audio, meta: { 'is_voice_message' => true })
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'voice.ogg', content_type: 'audio/ogg')
        attachment.save!

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'audio',
                                   audio: WebMock::API.hash_including({ id: 'uploaded_media_id', voice: true })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for regular audio attachment without voice flag' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'audio.ogg', content_type: 'audio/ogg')
        attachment.save!

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'audio'
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        result = service.send_message('+123456789', message)
        expect(result).to eq 'message_id'
        expect(WebMock).not_to(have_requested(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with { |req| JSON.parse(req.body).dig('audio', 'voice') })
      end

      # Measured against the live Graph API in #520: WhatsApp accepts the voice flag on every type
      # its own rejection message lists, and a phone renders all of them as a voice bubble. Only
      # opus carries a waveform. Refusing the rest turned a voice note into a file to tap, which
      # protected against nothing. This example used to assert the opposite.
      %w[sample.mp3 sample.m4a sample.aac].each do |fixture|
        it "sends the voice flag for a recorded #{fixture.split('.').last} too" do
          attachment = message.attachments.new(account_id: message.account_id, file_type: :audio,
                                               meta: { 'is_recorded_audio' => true })
          attachment.file.attach(io: Rails.root.join("spec/assets/#{fixture}").open, filename: fixture)

          stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
            .with(
              body: hash_including({
                                     messaging_product: 'whatsapp',
                                     to: '+123456789',
                                     type: 'audio',
                                     audio: WebMock::API.hash_including({ link: anything, voice: true })
                                   })
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end
      end

      # The payload type comes from `file_type`, not from the content type, so an audio file stored
      # as a plain file goes out as a document. `voice` is not a field a document payload has, and
      # WhatsApp rejects the send if it is there.
      it 'leaves the voice flag off when the attachment goes out as a document' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :file,
                                             meta: { 'is_voice_message' => true })
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.mp3').open, filename: 'sample.mp3')

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(body: hash_including({ messaging_product: 'whatsapp', to: '+123456789', type: 'document' }))
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
        expect(WebMock).not_to(have_requested(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with { |req| JSON.parse(req.body).dig('document', 'voice') })
      end

      # Chrome hands ActiveStorage `audio/ogg; codecs=opus` for a recording and the blob keeps the
      # string verbatim, and a media type is case-insensitive by spec, so a client may shout it.
      # Comparing the string whole would drop exactly the format the list exists for.
      ['audio/ogg; codecs=opus', 'AUDIO/OGG', ' audio/ogg ; codecs=opus'].each do |stored|
        it "reads the media type out of #{stored.inspect}" do
          attachment = message.attachments.new(account_id: message.account_id, file_type: :audio,
                                               meta: { 'is_recorded_audio' => true })
          attachment.file.attach(io: Rails.root.join('spec/assets/sample_opus.ogg').open, filename: 'voice.ogg')
          attachment.save!
          attachment.file.blob.update_column(:content_type, stored) # rubocop:disable Rails/SkipsModelValidations
          message.attachments.reload

          stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
            .with(
              body: hash_including({
                                     messaging_product: 'whatsapp',
                                     to: '+123456789',
                                     type: 'audio',
                                     audio: WebMock::API.hash_including({ id: 'uploaded_media_id', voice: true })
                                   })
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end
      end

      # The end of the path the cast in `Messages::MessageBuilder` protects: a caller that writes
      # `is_voice_message=false` through `attachments_metadata` over multipart sends the string,
      # and before the cast it arrived here as an explicit yes.
      it 'leaves the voice flag off for a flag the caller sent as the string false' do
        message = create(:message, message_type: :outgoing, content: nil, conversation: conversation)
        Messages::MessageBuilder.new(
          nil, message.conversation,
          ActionController::Parameters.new(
            content: nil,
            attachments: [Rack::Test::UploadedFile.new('spec/assets/sample.mp3', 'audio/mpeg')],
            attachments_metadata: { 'sample.mp3' => { is_voice_message: 'false' } }
          )
        ).perform

        built = message.conversation.messages.last
        expect(built.attachments.first.meta).to include('is_voice_message' => false)
        expect(service.send(:voice_message?, 'audio', built.attachments.first)).to be(false)
      end

      # A caller that says "this is not a voice message" is not the same as one that says nothing,
      # and both have to come out the same way: no flag. Both keys are set, because `false || nil`
      # is `nil` and would let a presence check and a nil check agree by accident. The API lets a
      # caller write either key through `attachments_metadata`.
      it 'leaves the voice flag off when the meta says false rather than being absent' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :audio,
                                             meta: { 'is_voice_message' => false, 'is_recorded_audio' => false })
        attachment.file.attach(io: Rails.root.join('spec/assets/sample_opus.ogg').open, filename: 'voice.ogg')

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'audio',
                                   audio: WebMock::API.hash_including({ link: anything })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
        expect(WebMock).not_to(have_requested(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with { |req| JSON.parse(req.body).dig('audio', 'voice') })
      end

      # The list is WhatsApp's, not "any audio". A type it does not accept for voice has to go out
      # as a plain audio attachment, or the send fails after the fact with an error about the type.
      it 'leaves the voice flag off for an audio type WhatsApp does not accept for voice' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :audio,
                                             meta: { 'is_recorded_audio' => true })
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.wav').open, filename: 'sample.wav')

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'audio',
                                   audio: WebMock::API.hash_including({ link: anything })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
        expect(WebMock).not_to(have_requested(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with { |req| JSON.parse(req.body).dig('audio', 'voice') })
      end

      it 'sends voice flag for recorded audio in ogg format' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :audio, meta: { 'is_recorded_audio' => true })
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'sample.ogg', content_type: 'audio/ogg')

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'audio',
                                   audio: WebMock::API.hash_including({ link: anything, voice: true })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'normalizes audio/opus to audio/ogg and sends voice flag for recorded audio' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :audio, meta: { 'is_recorded_audio' => true })
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'sample.ogg', content_type: 'audio/ogg')
        attachment.save!
        # Simulate Marcel detecting audio/opus (as happens with OGG Opus files in Marcel 1.1.0)
        attachment.file.blob.update_column(:content_type, 'audio/opus') # rubocop:disable Rails/SkipsModelValidations
        # The service reads the attachment the way a job does, straight from the database. Without
        # dropping the association cache it would keep the pre-update blob and never normalize.
        message.attachments.reload

        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(
            body: hash_including({
                                   messaging_product: 'whatsapp',
                                   to: '+123456789',
                                   type: 'audio',
                                   audio: WebMock::API.hash_including({ id: 'uploaded_media_id', voice: true })
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
        expect(attachment.file.blob.reload.content_type).to eq('audio/ogg')
      end
    end

    context 'when the media upload fails' do
      it 'falls back to sending the download url' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        stub_request(:post, media_upload_url).to_return(status: 429, body: {}.to_json, headers: response_headers)
        stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
          .with(body: hash_including({ image: WebMock::API.hash_including({ link: anything }) }))
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end
    end
  end

  describe '#send_interactive message' do
    context 'when called' do
      it 'calls message endpoints with button payload when number of items is less than or equal to 3' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   inbox: whatsapp_channel.inbox, content_type: 'input_select',
                                   content_attributes: {
                                     items: [
                                       { title: 'Burito', value: 'Burito' },
                                       { title: 'Pasta', value: 'Pasta' },
                                       { title: 'Sushi', value: 'Sushi' }
                                     ]
                                   })
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp', to: '+123456789',
              interactive: {
                type: 'button',
                body: {
                  text: 'test'
                },
                action: '{"buttons":[{"type":"reply","reply":{"id":"Burito","title":"Burito"}},{"type":"reply",' \
                        '"reply":{"id":"Pasta","title":"Pasta"}},{"type":"reply","reply":{"id":"Sushi","title":"Sushi"}}]}'
              }, type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints with list payload when descriptions are present' do
        items = [
          { title: 'Burito', value: 'Burito', description: 'A tortilla wrap with fillings' },
          { title: 'Pasta', value: 'Pasta', description: 'An Italian noodle dish' },
          { title: 'Sushi', value: 'Sushi', description: 'Rice and seafood rolls' }
        ]
        message = create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                                   content_type: 'input_select', content_attributes: { items: items })

        expected_action = {
          button: I18n.t('conversations.messages.whatsapp.list_button_label'),
          sections: [
            {
              rows: items.map do |item|
                { id: item[:value], title: item[:title], description: item[:description] }
              end
            }
          ]
        }.to_json

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp', to: '+123456789',
              interactive: {
                type: 'list',
                body: {
                  text: 'test'
                },
                action: expected_action
              },
              type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints with list payload when number of items is greater than 3' do
        items = [
          { title: 'Burito', value: 'Burito', description: 'A tortilla wrap with fillings' },
          { title: 'Pasta', value: 'Pasta', description: 'An Italian noodle dish' },
          { title: 'Sushi', value: 'Sushi', description: 'Rice and seafood rolls' },
          { title: 'Salad', value: 'Salad', description: 'Fresh mixed vegetables' }
        ]
        message = create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                                   content_type: 'input_select', content_attributes: { items: items })

        expected_action = {
          button: I18n.t('conversations.messages.whatsapp.list_button_label'),
          sections: [
            {
              rows: items.map do |item|
                { id: item[:value], title: item[:title], description: item[:description] }
              end
            }
          ]
        }.to_json

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp', to: '+123456789',
              interactive: {
                type: 'list',
                body: {
                  text: 'test'
                },
                action: expected_action
              },
              type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end
    end
  end

  describe '#send_template' do
    let(:template_info) do
      {
        name: 'test_template',
        namespace: 'test_namespace',
        lang_code: 'en_US',
        parameters: [{ type: 'text', text: 'test' }]
      }
    end

    let(:template_body) do
      {
        messaging_product: 'whatsapp',
        recipient_type: 'individual', # Added recipient_type field
        to: '+123456789',
        type: 'template',
        template: {
          name: template_info[:name],
          language: {
            policy: 'deterministic',
            code: template_info[:lang_code]
          },
          components: template_info[:parameters] # Changed to use parameters directly (enhanced format)
        }
      }
    end

    context 'when called' do
      it 'calls message endpoints with template params for template messages' do
        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: template_body.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_template('+123456789', template_info, message)).to eq('message_id')
      end
    end
  end

  describe 'when the recipient is a Business-Scoped User ID (BSUID)' do
    # Meta requires a BSUID to be sent in the `recipient` field (with recipient_type: individual), not `to`.
    let(:bsuid) { 'BR.13491208655302741918' }
    let(:parent_bsuid) { 'IN.ENT.9081726354' }

    it 'sends a text message via the recipient field instead of to' do
      stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            context: nil,
            recipient_type: 'individual',
            recipient: bsuid,
            text: { body: message.content },
            type: 'text'
          }.to_json
        )
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      expect(service.send_message(bsuid, message)).to eq 'message_id'
    end

    it 'sends a text message to a parent BSUID via the recipient field instead of to' do
      stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            context: nil,
            recipient_type: 'individual',
            recipient: parent_bsuid,
            text: { body: message.content },
            type: 'text'
          }.to_json
        )
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      expect(service.send_message(parent_bsuid, message)).to eq 'message_id'
    end

    it 'sends a template via the recipient field instead of to' do
      template_info = { name: 'test_template', namespace: 'test_namespace', lang_code: 'en_US', parameters: [] }
      stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
        .with(body: hash_including({ messaging_product: 'whatsapp', recipient_type: 'individual', recipient: bsuid, type: 'template' }))
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      expect(service.send_template(bsuid, template_info, message)).to eq 'message_id'
    end

    it 'sends an interactive message via the recipient field instead of to' do
      interactive_message = create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                                             content_type: 'input_select',
                                             content_attributes: { items: [{ title: 'Burito', value: 'Burito' }] })
      stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
        .with(body: hash_including({ messaging_product: 'whatsapp', recipient_type: 'individual', recipient: bsuid, type: 'interactive' }))
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      expect(service.send_message(bsuid, interactive_message)).to eq 'message_id'
    end

    it 'sends an attachment via the recipient field instead of to' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      attachment.save!

      stub_request(:post, 'https://graph.facebook.com/v24.0/123456789/messages')
        .with(body: hash_including({ messaging_product: 'whatsapp', recipient_type: 'individual', recipient: bsuid, type: 'image' }))
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      expect(service.send_message(bsuid, message)).to eq 'message_id'
    end
  end

  describe '#sync_templates' do
    context 'when called' do
      context 'with a business management token' do
        let(:business_management_token) { 'business-token' }

        before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true) }

        it 'uses it instead of the provider API key' do
          request = stub_request(
            :get,
            'https://graph.facebook.com/v14.0/123456789/message_templates'
          ).with(
            headers: { 'Authorization' => 'Bearer business-token' }
          ).to_return(status: 200, headers: response_headers, body: { data: [] }.to_json)

          subject.sync_templates

          expect(request).to have_been_requested
        end
      end

      context 'without a business management token' do
        before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true) }

        it 'uses the provider API key' do
          request = stub_request(
            :get,
            'https://graph.facebook.com/v14.0/123456789/message_templates'
          ).with(
            headers: { 'Authorization' => 'Bearer test_key' }
          ).to_return(status: 200, headers: response_headers, body: { data: [] }.to_json)

          subject.sync_templates

          expect(request).to have_been_requested
        end
      end

      context 'with a stored business management token outside Chatwoot Cloud' do
        let(:business_management_token) { 'business-token' }

        before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false) }

        it 'uses the provider API key' do
          request = stub_request(
            :get,
            'https://graph.facebook.com/v14.0/123456789/message_templates'
          ).with(
            headers: { 'Authorization' => 'Bearer test_key' }
          ).to_return(status: 200, headers: response_headers, body: { data: [] }.to_json)

          subject.sync_templates

          expect(request).to have_been_requested
        end
      end

      it 'updated the message templates' do
        request_headers = { 'Authorization' => 'Bearer test_key' }
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates')
          .with(headers: request_headers)
          .to_return(
            status: 200,
            headers: response_headers,
            body: {
              data: [{ id: '123456789', name: 'test_template' }],
              paging: {
                cursors: { after: 'cursor-1' },
                next: 'https://graph.facebook.com/v14.0/123456789/message_templates?after=cursor-1&access_token=test_key'
              }
            }.to_json
          )
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?after=cursor-1')
          .with(headers: request_headers)
          .to_return(
            status: 200,
            headers: response_headers,
            body: {
              data: [{ id: '123456789', name: 'next_template' }],
              paging: {
                cursors: { after: 'cursor-2' },
                next: 'https://graph.facebook.com/v14.0/123456789/message_templates?after=cursor-2&access_token=test_key'
              }
            }.to_json
          )
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?after=cursor-2')
          .with(headers: request_headers)
          .to_return(
            status: 200,
            headers: response_headers,
            body: { data: [{ id: '123456789', name: 'last_template' }] }.to_json
          )

        timstamp = whatsapp_channel.reload.message_templates_last_updated
        expect(whatsapp_channel.account).to receive(:update_cache_key).with('inbox').and_call_original
        subject.sync_templates
        expect(whatsapp_channel.reload.message_templates.first).to eq({ id: '123456789', name: 'test_template' }.stringify_keys)
        expect(whatsapp_channel.reload.message_templates.second).to eq({ id: '123456789', name: 'next_template' }.stringify_keys)
        expect(whatsapp_channel.reload.message_templates.last).to eq({ id: '123456789', name: 'last_template' }.stringify_keys)
        expect(whatsapp_channel.reload.message_templates_last_updated).not_to eq(timstamp)
      end

      it 'does not bump the inbox cache key when no templates are returned' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates')
          .with(headers: { 'Authorization' => 'Bearer test_key' })
          .to_return(status: 200, headers: response_headers, body: { data: [] }.to_json)

        expect(whatsapp_channel.account).not_to receive(:update_cache_key)
        subject.sync_templates
      end

      it 'updates message_templates_last_updated even when template request fails' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates')
          .with(headers: { 'Authorization' => 'Bearer test_key' })
          .to_return(status: 401)

        timstamp = whatsapp_channel.reload.message_templates_last_updated
        subject.sync_templates
        expect(whatsapp_channel.reload.message_templates_last_updated).not_to eq(timstamp)
      end
    end
  end

  describe '#validate_provider_config' do
    context 'when called' do
      it 'returns true if valid' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
        expect(subject.validate_provider_config?).to be(true)
        expect(whatsapp_channel.errors.present?).to be(false)
      end

      it 'returns false if invalid' do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key').to_return(status: 401)
        expect(subject.validate_provider_config?).to be(false)
      end
    end

    # Webhooks would be verified with it, so a secret from another app would refuse every one of them.
    context 'when the app secret changes' do
      let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }

      before do
        stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
        stub_request(:get, %r{/123456789/phone_numbers}).to_return(status: 200, body: { data: [{ id: '123456789' }] }.to_json,
                                                                   headers: { 'Content-Type' => 'application/json' })
        allow(Whatsapp::FacebookApiClient).to receive(:new).with('test_key').and_return(api_client)
        whatsapp_channel.provider_config = whatsapp_channel.provider_config.merge('app_secret' => 'new_secret')
      end

      it 'refuses a secret that does not match the token' do
        allow(api_client).to receive(:app_secret_matches?).with('new_secret').and_return(false)

        expect(service.validate_provider_config?).to be(false)
      end

      it 'accepts the secret of the app that issued the token' do
        allow(api_client).to receive(:app_secret_matches?).with('new_secret').and_return(true)

        expect(service.validate_provider_config?).to be(true)
      end
    end

    # A token from another Meta app would leave the inbox checking webhooks with the wrong secret.
    context 'when only the token changes' do
      let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }

      before do
        whatsapp_channel.update_column(:provider_config, whatsapp_channel.provider_config.merge('app_secret' => 'kept_secret')) # rubocop:disable Rails/SkipsModelValidations
        whatsapp_channel.reload.provider_config = whatsapp_channel.provider_config.merge('api_key' => 'other_app_token')
        stub_request(:get, %r{/123456789/message_templates}).to_return(status: 200)
        stub_request(:get, %r{/123456789/phone_numbers}).to_return(status: 200, body: { data: [{ id: '123456789' }] }.to_json,
                                                                   headers: { 'Content-Type' => 'application/json' })
        allow(Whatsapp::FacebookApiClient).to receive(:new).with('other_app_token').and_return(api_client)
      end

      it 'checks the stored secret against the new token' do
        allow(api_client).to receive(:app_secret_matches?).with('kept_secret').and_return(false)

        expect(service.validate_provider_config?).to be(false)
      end
    end
  end

  describe 'Ability to configure Base URL' do
    context 'when environment variable WHATSAPP_CLOUD_BASE_URL is not set' do
      it 'uses the default base url' do
        expect(subject.send(:api_base_path)).to eq('https://graph.facebook.com')
      end
    end

    context 'when environment variable WHATSAPP_CLOUD_BASE_URL is set' do
      it 'uses the base url from the environment variable' do
        with_modified_env WHATSAPP_CLOUD_BASE_URL: 'http://test.com' do
          expect(subject.send(:api_base_path)).to eq('http://test.com')
        end
      end
    end
  end

  describe '#handle_error' do
    let(:error_message) { 'Invalid message format' }
    let(:error_response) do
      {
        'error' => {
          'message' => error_message,
          'code' => 100
        }
      }
    end

    let(:error_response_object) do
      instance_double(
        HTTParty::Response,
        body: error_response.to_json,
        parsed_response: error_response
      )
    end

    before do
      allow(Rails.logger).to receive(:error)
    end

    context 'when there is a message' do
      it 'logs error and updates message status' do
        service.instance_variable_set(:@message, message)
        service.send(:handle_error, error_response_object, message)

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq(error_message)
      end
    end

    context 'when error message is blank' do
      let(:error_response_object) do
        instance_double(
          HTTParty::Response,
          body: '{}',
          parsed_response: {}
        )
      end

      it 'logs error but does not update message' do
        service.instance_variable_set(:@message, message)
        service.send(:handle_error, error_response_object, message)

        expect(message.reload.status).not_to eq('failed')
        expect(message.reload.external_error).to be_nil
      end
    end
  end

  describe 'CSAT template methods' do
    let(:mock_csat_template_service) { instance_double(Whatsapp::CsatTemplateService) }
    let(:expected_template_name) { "customer_satisfaction_survey_#{whatsapp_channel.inbox.id}" }
    let(:template_config) do
      {
        name: expected_template_name,
        language: 'en',
        category: 'UTILITY'
      }
    end

    before do
      allow(Whatsapp::CsatTemplateService).to receive(:new)
        .with(whatsapp_channel)
        .and_return(mock_csat_template_service)
    end

    describe '#create_csat_template' do
      it 'delegates to csat_template_service with correct config' do
        allow(mock_csat_template_service).to receive(:create_template)
          .with(template_config)
          .and_return({ success: true, template_id: '123' })

        result = service.create_csat_template(template_config)

        expect(mock_csat_template_service).to have_received(:create_template).with(template_config)
        expect(result).to eq({ success: true, template_id: '123' })
      end
    end

    describe '#delete_csat_template' do
      it 'delegates to csat_template_service with default template name' do
        allow(mock_csat_template_service).to receive(:delete_template)
          .with(expected_template_name)
          .and_return({ success: true })

        result = service.delete_csat_template

        expect(mock_csat_template_service).to have_received(:delete_template).with(expected_template_name)
        expect(result).to eq({ success: true })
      end

      it 'delegates to csat_template_service with custom template name' do
        custom_template_name = 'custom_csat_template'
        allow(mock_csat_template_service).to receive(:delete_template)
          .with(custom_template_name)
          .and_return({ success: true })

        result = service.delete_csat_template(custom_template_name)

        expect(mock_csat_template_service).to have_received(:delete_template).with(custom_template_name)
        expect(result).to eq({ success: true })
      end
    end

    describe '#get_template_status' do
      it 'delegates to csat_template_service with template name' do
        template_name = 'customer_survey_template'
        expected_response = { success: true, template: { status: 'APPROVED' } }
        allow(mock_csat_template_service).to receive(:get_template_status)
          .with(template_name)
          .and_return(expected_response)

        result = service.get_template_status(template_name)

        expect(mock_csat_template_service).to have_received(:get_template_status).with(template_name)
        expect(result).to eq(expected_response)
      end
    end

    describe 'csat_template_service memoization' do
      it 'creates and memoizes the csat_template_service instance' do
        allow(Whatsapp::CsatTemplateService).to receive(:new)
          .with(whatsapp_channel)
          .and_return(mock_csat_template_service)
        allow(mock_csat_template_service).to receive(:get_template_status)
          .and_return({ success: true })

        # Call multiple methods that use the service
        service.get_template_status('test1')
        service.get_template_status('test2')

        # Verify the service was only instantiated once
        expect(Whatsapp::CsatTemplateService).to have_received(:new).once
      end
    end
  end

  describe '#toggle_typing_status' do
    let(:conversation) { create(:conversation) }

    it 'calls messages endpoint with typing indicator for "conversation.typing_on"' do
      stub_request(:post, 'https://graph.facebook.com/v23.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            message_id: message.source_id,
            status: 'read',
            typing_indicator: { type: 'text' }
          }.to_json
        )
        .to_return(status: 200, body: { success: true }.to_json, headers: response_headers)

      expect(service.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, last_message: message)).to be(true)
    end

    it 'calls messages endpoint with typing indicator for "conversation.recording"' do
      stub_request(:post, 'https://graph.facebook.com/v23.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            message_id: message.source_id,
            status: 'read',
            typing_indicator: { type: 'text' }
          }.to_json
        )
        .to_return(status: 200, body: { success: true }.to_json, headers: response_headers)

      expect(service.toggle_typing_status(Events::Types::CONVERSATION_RECORDING, last_message: message)).to be(true)
    end

    it 'does not call messages endpoint with typing indicator for "conversation.typing_off"' do
      expect(service.toggle_typing_status(Events::Types::CONVERSATION_TYPING_OFF, last_message: message)).to be(false)
    end

    it 'logs error on failure' do
      allow(Rails.logger).to receive(:error).with('Request failed')
      stub_request(:post, 'https://graph.facebook.com/v23.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            message_id: message.source_id,
            status: 'read',
            typing_indicator: { type: 'text' }
          }.to_json
        )
        .to_return(status: 500, body: 'Request failed')

      service.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, last_message: message)

      expect(Rails.logger).to have_received(:error)
    end
  end

  describe '#read_messages' do
    it 'calls messages endpoint to mark last message as read' do
      stub_request(:post, 'https://graph.facebook.com/v23.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            message_id: message.source_id,
            status: 'read'
          }.to_json
        )
        .to_return(status: 200, body: { success: true }.to_json, headers: response_headers)

      messages = [create(:message), message]
      expect(service.read_messages(messages)).to be(true)
    end

    it 'logs error on failure' do
      allow(Rails.logger).to receive(:error).with('Request failed')
      stub_request(:post, 'https://graph.facebook.com/v23.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            message_id: message.source_id,
            status: 'read'
          }.to_json
        )
        .to_return(status: 500, body: 'Request failed')

      service.read_messages([message])

      expect(Rails.logger).to have_received(:error)
    end
  end

  describe '#send_reaction_message' do
    it 'calls messages endpoint to send reaction message' do
      message_with_reaction = create(:message, message_type: :outgoing, content: '👍', conversation: conversation,
                                               inbox: whatsapp_channel.inbox, content_attributes: { is_reaction: true, in_reply_to: message.id })

      stub_request(:post, 'https://graph.facebook.com/v23.0/123456789/messages')
        .with(
          body: {
            messaging_product: 'whatsapp',
            recipient_type: 'individual',
            to: '+123456789',
            type: 'reaction',
            reaction: {
              message_id: message.source_id,
              emoji: '👍'
            }
          }.to_json
        )
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      expect(service.send_message('+123456789', message_with_reaction)).to eq 'message_id'
    end
  end

  describe '#upload_media' do
    let(:upload_url) { 'https://graph.facebook.com/v24.0/123456789/media' }
    let(:file) { Tempfile.new(['sample', '.jpg']) }

    after { file.close! }

    it 'returns the media id' do
      stub_request(:post, upload_url).to_return(status: 200, body: { id: '4565669250245108' }.to_json, headers: response_headers)

      expect(service.upload_media(file, 'image/jpeg')).to eq '4565669250245108'
    end

    # `error.message` for a rejected upload is only "(#100) Invalid parameter"; the actionable reason
    # (sample media above Meta's size limit, unsupported format) lives in `error_data.details`.
    it 'raises with the detail Meta gives, not the generic message' do
      body = {
        error: {
          message: '(#100) Invalid parameter',
          code: 100,
          error_data: { messaging_product: 'whatsapp', details: 'File Too Large: The file you uploaded is too large.' }
        }
      }
      stub_request(:post, upload_url).to_return(status: 400, body: body.to_json, headers: response_headers)

      expect { service.upload_media(file, 'video/mp4') }
        .to raise_error(CustomExceptions::Whatsapp::MediaUploadError, /File Too Large/)
    end

    # MediaUploadError fails the message for good, so a blip must not raise it.
    it 'lets a server error propagate so the job can be retried' do
      stub_request(:post, upload_url).to_return(status: 503, body: '', headers: response_headers)

      expect { service.upload_media(file, 'image/jpeg') }.to raise_error(Net::HTTPFatalError)
    end

    it 'lets a rate limit propagate so the job can be retried' do
      stub_request(:post, upload_url).to_return(status: 429, body: '', headers: response_headers)

      expect { service.upload_media(file, 'image/jpeg') }.to raise_error(Net::HTTPClientException)
    end

    # Graph reports throttling and other passing conditions inside a 400 envelope, so the status alone
    # would read them as a rejected file.
    it 'lets a transient error dressed as HTTP 400 propagate so the job can be retried' do
      body = { error: { message: '(#4) Application request limit reached', code: 4, is_transient: true } }
      stub_request(:post, upload_url).to_return(status: 400, body: body.to_json, headers: response_headers)

      expect { service.upload_media(file, 'image/jpeg') }.to raise_error(Net::HTTPClientException)
    end
  end
end
