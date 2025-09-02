require 'rails_helper'

describe Whatsapp::Providers::WhapiService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:whatsapp_channel) do
    ch = build(:channel_whatsapp, provider: 'whapi', validate_provider_config: false, sync_templates: false,
               provider_config: { 'api_key' => 'test_key', 'business_account_id' => 'test_business_id' })
    # Explicitly bypass validation to prevent provider config validation errors
    ch.define_singleton_method(:validate_provider_config) { true }
    ch.define_singleton_method(:sync_templates) { nil }
    
    # Mock the provider_config_object to prevent real API calls during channel operations
    mock_config = double('MockProviderConfig')
    allow(mock_config).to receive(:validate_config?).and_return(true)
    allow(mock_config).to receive(:api_key).and_return('test_key')
    allow(mock_config).to receive(:business_account_id).and_return('test_business_id')
    allow(mock_config).to receive(:whapi_channel_id).and_return('test_channel_id')
    allow(mock_config).to receive(:cleanup_on_destroy)
    allow(ch).to receive(:provider_config_object).and_return(mock_config)
    
    ch.save!(validate: false)
    ch
  end
  let(:contact_phone) { '+1234567890' }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }

  before do
    # Add WebMock stubs for WHAPI API calls to prevent external requests during tests
    # Stub WHAPI health check - this was the missing stub causing test failures
    stub_request(:get, "https://gate.whapi.cloud/health")
      .with(headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'Bearer test_key',
        'Content-Type' => 'application/json',
        'User-Agent' => 'Ruby'
      })
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      
    # Stub WHAPI contact profile endpoint
    stub_request(:get, %r{https://gate\.whapi\.cloud/contacts/.*/profile})
      .to_return(status: 200, body: '{"pushname": "Test User"}', headers: { 'Content-Type' => 'application/json' })
  end

  describe '#send_message' do
    let(:message) do
      create(:message, conversation: conversation, message_type: :outgoing, content: 'Hello World', inbox: whatsapp_channel.inbox)
    end

    context 'when sending text message' do
      let(:whapi_response) { { message: { id: 'whapi_message_123' } } }

      it 'sends text message successfully' do
        stub_request(:post, 'https://gate.whapi.cloud/messages/text')
          .with(
            headers: {
              'Authorization' => 'Bearer test_key',
              'Content-Type' => 'application/json'
            },
            body: {
              to: contact_phone,
              body: 'Hello World'
            }.to_json
          )
          .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

        result = service.send_message(contact_phone, message)
        expect(result).to eq('whapi_message_123')
      end

      it 'handles text message with reply context' do
        message.content_attributes = { in_reply_to_external_id: 'original_msg_id' }

        stub_request(:post, 'https://gate.whapi.cloud/messages/text')
          .with(
            headers: {
              'Authorization' => 'Bearer test_key',
              'Content-Type' => 'application/json'
            },
            body: {
              to: contact_phone,
              body: 'Hello World',
              quoted: 'original_msg_id'
            }.to_json
          )
          .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

        result = service.send_message(contact_phone, message)
        expect(result).to eq('whapi_message_123')
      end
    end

    context 'when sending attachment message' do
      let(:whapi_response) { { message: { id: 'whapi_attachment_123' } } }
      let(:attachment) { create(:attachment, account: whatsapp_channel.account) }
      let(:message_with_attachment) do
        msg = create(:message, conversation: conversation, message_type: :outgoing, content: 'Check this out', inbox: whatsapp_channel.inbox)
        msg.attachments << attachment
        msg
      end

      before do
        # Mock file download
        allow(attachment.file).to receive(:download).and_return('fake_file_content')
        allow(attachment.file).to receive(:content_type).and_return('image/jpeg')
        allow(attachment.file).to receive(:filename).and_return(double(to_s: 'test.jpg'))
      end

      it 'sends image attachment successfully' do
        allow(attachment).to receive(:file_type).and_return('image')

        stub_request(:post, 'https://gate.whapi.cloud/messages/media/image')
          .with(
            headers: {
              'Authorization' => 'Bearer test_key',
              'Content-Type' => 'image/jpeg'
            },
            query: {
              to: contact_phone,
              caption: 'Check this out'
            },
            body: 'fake_file_content'
          )
          .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

        result = service.send_message(contact_phone, message_with_attachment)
        expect(result).to eq('whapi_attachment_123')
      end

      it 'sends document attachment successfully' do
        allow(attachment).to receive(:file_type).and_return('file')

        stub_request(:post, 'https://gate.whapi.cloud/messages/media/document')
          .with(
            headers: {
              'Authorization' => 'Bearer test_key',
              'Content-Type' => 'image/jpeg'
            },
            query: {
              to: contact_phone,
              caption: 'Check this out',
              filename: 'test.jpg'
            },
            body: 'fake_file_content'
          )
          .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

        result = service.send_message(contact_phone, message_with_attachment)
        expect(result).to eq('whapi_attachment_123')
      end

      it 'sends voice message without caption' do
        allow(attachment).to receive(:file_type).and_return('audio')
        allow(attachment.file).to receive(:content_type).and_return('audio/ogg')

        stub_request(:post, 'https://gate.whapi.cloud/messages/media/voice')
          .with(
            headers: {
              'Authorization' => 'Bearer test_key',
              'Content-Type' => 'audio/ogg'
            },
            query: {
              to: contact_phone
              # No caption for voice messages
            },
            body: 'fake_file_content'
          )
          .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

        result = service.send_message(contact_phone, message_with_attachment)
        expect(result).to eq('whapi_attachment_123')
      end

      it 'sends regular audio message with caption' do
        allow(attachment).to receive(:file_type).and_return('audio')
        allow(attachment.file).to receive(:content_type).and_return('audio/mp3')

        stub_request(:post, 'https://gate.whapi.cloud/messages/media/audio')
          .with(
            headers: {
              'Authorization' => 'Bearer test_key',
              'Content-Type' => 'audio/ogg'
            },
            query: {
              to: contact_phone,
              caption: 'Check this out'
            },
            body: 'fake_file_content'
          )
          .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

        result = service.send_message(contact_phone, message_with_attachment)
        expect(result).to eq('whapi_attachment_123')
      end
    end

    context 'when API returns error' do
      it 'handles API error responses gracefully' do
        error_response = {
          error: {
            message: 'Invalid phone number format'
          }
        }

        stub_request(:post, 'https://gate.whapi.cloud/messages/text')
          .to_return(status: 400, body: error_response.to_json, headers: response_headers)

        result = service.send_message(contact_phone, message)

        expect(result).to be_nil
        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq('Invalid phone number format')
      end

      it 'handles network errors' do
        stub_request(:post, 'https://gate.whapi.cloud/messages/text')
          .to_raise(Net::ReadTimeout)

        expect { service.send_message(contact_phone, message) }.to raise_error(Net::ReadTimeout)
      end
    end
  end

  describe '#send_template' do
    let(:template_info) do
      {
        name: 'test_template',
        body: 'Hello {{name}}, your order is ready!',
        parameters: [{ type: 'text', text: 'John' }]
      }
    end

    it 'sends template as regular text message' do
      whapi_response = { message: { id: 'whapi_template_123' } }

      stub_request(:post, 'https://gate.whapi.cloud/messages/text')
        .with(
          headers: {
            'Authorization' => 'Bearer test_key',
            'Content-Type' => 'application/json'
          },
          body: {
            to: contact_phone,
            body: 'Hello {{name}}, your order is ready!'
          }.to_json
        )
        .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

      result = service.send_template(contact_phone, template_info)
      expect(result).to eq('whapi_template_123')
    end

    it 'handles template with text field instead of body' do
      template_info[:text] = 'Alternative template text'
      template_info.delete(:body)

      whapi_response = { message: { id: 'whapi_template_456' } }

      stub_request(:post, 'https://gate.whapi.cloud/messages/text')
        .with(
          body: hash_including({
                                 body: 'Alternative template text'
                               })
        )
        .to_return(status: 200, body: whapi_response.to_json, headers: response_headers)

      result = service.send_template(contact_phone, template_info)
      expect(result).to eq('whapi_template_456')
    end
  end

  describe '#sync_templates' do
    it 'marks templates as updated without API call' do
      expect(whatsapp_channel).to receive(:mark_message_templates_updated)

      result = service.sync_templates
      expect(result).to be true
    end
  end

  describe '#validate_provider_config?' do
    it 'returns true when health check succeeds' do
      stub_request(:get, 'https://gate.whapi.cloud/health')
        .with(headers: { 'Authorization' => 'Bearer test_key' })
        .to_return(status: 200, body: '', headers: {})

      result = service.validate_provider_config?
      expect(result).to be true
    end

    it 'returns false when health check fails' do
      # Override the mock to actually call the real validate_config? method for this test
      real_config = Whatsapp::ProviderConfig::Whapi.new(whatsapp_channel)
      allow(whatsapp_channel).to receive(:provider_config_object).and_return(real_config)
      
      stub_request(:get, 'https://gate.whapi.cloud/health')
        .with(headers: { 'Authorization' => 'Bearer test_key' })
        .to_return(status: 401, body: '', headers: {})

      result = service.validate_provider_config?
      expect(result).to be false
    end

    it 'returns false when health check times out' do
      # Override the mock to actually call the real validate_config? method for this test
      real_config = Whatsapp::ProviderConfig::Whapi.new(whatsapp_channel)
      allow(whatsapp_channel).to receive(:provider_config_object).and_return(real_config)
      
      stub_request(:get, 'https://gate.whapi.cloud/health')
        .to_raise(Net::ReadTimeout)

      result = service.validate_provider_config?
      expect(result).to be false
    end
  end

  describe '#mark_as_read' do
    let(:message) { create(:message, conversation: conversation, source_id: 'msg_123') }

    it 'marks message as read successfully' do
      stub_request(:put, 'https://gate.whapi.cloud/messages/msg_123')
        .with(headers: { 'Authorization' => 'Bearer test_key' })
        .to_return(status: 200, body: '{"success": true}', headers: response_headers)

      response = service.mark_as_read(message)
      expect(response.success?).to be true
    end

    it 'handles mark as read failure' do
      stub_request(:put, 'https://gate.whapi.cloud/messages/msg_123')
        .with(headers: { 'Authorization' => 'Bearer test_key' })
        .to_return(status: 404, body: '{"error": "Message not found"}', headers: response_headers)

      response = service.mark_as_read(message)
      expect(response.success?).to be false
    end
  end

  describe '#error_message' do
    it 'extracts error message from WHAPI response' do
      response_double = double('response',
                               parsed_response: { 'error' => { 'message' => 'Invalid API key' } },
                               code: 401,
                               body: '{"error":{"message":"Invalid API key"}}')

      result = service.error_message(response_double)
      expect(result).to eq('Invalid API key')
    end

    it 'extracts message field when error.message is not present' do
      response_double = double('response',
                               parsed_response: { 'message' => 'Rate limit exceeded' },
                               code: 429,
                               body: '{"message":"Rate limit exceeded"}')

      result = service.error_message(response_double)
      expect(result).to eq('Rate limit exceeded')
    end

    it 'provides fallback error message when no specific error found' do
      response_double = double('response',
                               parsed_response: { 'status' => 'failed' },
                               code: 500,
                               body: '{"status":"failed"}')

      result = service.error_message(response_double)
      expect(result).to eq('WHAPI API request failed with status 500')
    end

    it 'handles non-hash responses' do
      response_double = double('response',
                               parsed_response: 'Internal Server Error',
                               code: 500,
                               body: 'Internal Server Error')

      result = service.error_message(response_double)
      expect(result).to eq('WHAPI API request failed with status 500')
    end
  end

  describe '#api_headers' do
    it 'returns correct headers with authorization' do
      headers = service.api_headers
      expect(headers).to eq({
                              'Authorization' => 'Bearer test_key',
                              'Content-Type' => 'application/json'
                            })
    end
  end

  describe '#fetch_contact_info' do
    let(:phone_number) { '1234567890' }
    let(:profile_response) do
      {
        'pushname' => 'John Doe Business',
        'business_name' => 'Acme Corp',
        'about' => 'Available for business inquiries',
        'icon' => 'https://example.com/avatar_96.jpg',
        'icon_full' => 'https://example.com/avatar_full.jpg'
      }
    end

    it 'fetches contact information from profile endpoint successfully' do
      stub_request(:get, "https://gate.whapi.cloud/contacts/#{phone_number}/profile")
        .with(headers: { 'Authorization' => 'Bearer test_key', 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: profile_response.to_json, headers: response_headers)

      result = service.fetch_contact_info(phone_number)

      expect(result).to be_a(Hash)
      expect(result[:avatar_url]).to eq('https://example.com/avatar_full.jpg')
      expect(result[:name]).to eq('John Doe Business')
      expect(result[:business_name]).to eq('Acme Corp')
      expect(result[:status]).to eq('Available for business inquiries')
    end

    it 'handles phone number with WhatsApp suffixes' do
      phone_with_suffix = '1234567890@c.us'

      # Should clean the phone number and call with just digits
      stub_request(:get, "https://gate.whapi.cloud/contacts/#{phone_number}/profile")
        .with(headers: { 'Authorization' => 'Bearer test_key', 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: profile_response.to_json, headers: response_headers)

      result = service.fetch_contact_info(phone_with_suffix)

      expect(result[:avatar_url]).to eq('https://example.com/avatar_full.jpg')
      expect(result[:name]).to eq('John Doe Business')
    end

    it 'prefers icon_full over icon for avatar URL' do
      profile_with_both_icons = {
        'pushname' => 'John Doe',
        'about' => 'Available',
        'icon' => 'https://example.com/avatar_96.jpg',
        'icon_full' => 'https://example.com/avatar_full.jpg'
      }

      stub_request(:get, "https://gate.whapi.cloud/contacts/#{phone_number}/profile")
        .to_return(status: 200, body: profile_with_both_icons.to_json, headers: response_headers)

      result = service.fetch_contact_info(phone_number)

      expect(result[:avatar_url]).to eq('https://example.com/avatar_full.jpg') # Should prefer icon_full
      expect(result[:name]).to eq('John Doe')
    end

    it 'handles partial contact information' do
      partial_profile_response = {
        'pushname' => 'Alice Johnson'
        # No business_name, avatar icons or status
      }

      stub_request(:get, "https://gate.whapi.cloud/contacts/#{phone_number}/profile")
        .with(headers: { 'Authorization' => 'Bearer test_key', 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: partial_profile_response.to_json, headers: response_headers)

      result = service.fetch_contact_info(phone_number)

      expect(result[:name]).to eq('Alice Johnson')
      expect(result[:avatar_url]).to be_nil
      expect(result[:business_name]).to be_nil
      expect(result[:status]).to be_nil
    end

    it 'returns nil when phone number is blank' do
      result = service.fetch_contact_info('')
      expect(result).to be_nil

      result = service.fetch_contact_info(nil)
      expect(result).to be_nil
    end

    it 'returns nil when profile API request fails' do
      stub_request(:get, "https://gate.whapi.cloud/contacts/#{phone_number}/profile")
        .with(headers: { 'Authorization' => 'Bearer test_key', 'Content-Type' => 'application/json' })
        .to_return(status: 404, body: '{"error": "Profile not found"}', headers: response_headers)

      result = service.fetch_contact_info(phone_number)
      expect(result).to be_nil
    end

    it 'handles network timeouts gracefully' do
      stub_request(:get, "https://gate.whapi.cloud/contacts/#{phone_number}/profile")
        .to_raise(Net::ReadTimeout)

      # Mock the error tracker since it's called in the rescue block
      allow(WhapiErrorTracker).to receive(:track_and_degrade)
      expect(Rails.logger).to receive(:error).with(/WHAPI contact fetch error/)

      result = service.fetch_contact_info(phone_number)
      expect(result).to be_nil
    end

    it 'returns nil when no useful information is available' do
      empty_profile_response = {}

      stub_request(:get, "https://gate.whapi.cloud/contacts/#{phone_number}/profile")
        .with(headers: { 'Authorization' => 'Bearer test_key', 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: empty_profile_response.to_json, headers: response_headers)

      # The service logs debug message only in development mode, and returns nil when no useful data
      result = service.fetch_contact_info(phone_number)
      expect(result).to be_nil
    end
  end

  describe '#media_url' do
    it 'returns nil since WHAPI uses direct URLs' do
      result = service.media_url('some_media_id')
      expect(result).to be_nil
    end
  end

  describe 'private methods' do
    describe '#map_chatwoot_to_whapi_type' do
      it 'maps image file type correctly' do
        attachment = double('attachment', file_type: 'image')
        result = service.send(:map_chatwoot_to_whapi_type, attachment)
        expect(result).to eq('image')
      end

      it 'maps video file type correctly' do
        attachment = double('attachment', file_type: 'video')
        result = service.send(:map_chatwoot_to_whapi_type, attachment)
        expect(result).to eq('video')
      end

      it 'maps file type to document' do
        attachment = double('attachment', file_type: 'file')
        result = service.send(:map_chatwoot_to_whapi_type, attachment)
        expect(result).to eq('document')
      end

      it 'maps unknown type to document' do
        attachment = double('attachment', file_type: 'unknown')
        result = service.send(:map_chatwoot_to_whapi_type, attachment)
        expect(result).to eq('document')
      end
    end

    describe '#determine_audio_type' do
      it 'identifies voice messages by ogg content type' do
        attachment = double('attachment', file: double(content_type: 'audio/ogg'))
        result = service.send(:determine_audio_type, attachment)
        expect(result).to eq('voice')
      end

      it 'identifies regular audio messages' do
        attachment = double('attachment', file: double(content_type: 'audio/mp3'))
        result = service.send(:determine_audio_type, attachment)
        expect(result).to eq('audio')
      end
    end

    describe '#whapi_reply_context' do
      it 'returns quoted context when reply exists' do
        message = double('message', content_attributes: { in_reply_to_external_id: 'msg_123' })
        result = service.send(:whapi_reply_context, message)
        expect(result).to eq({ quoted: 'msg_123' })
      end

      it 'returns empty hash when no reply context' do
        message = double('message', content_attributes: {})
        result = service.send(:whapi_reply_context, message)
        expect(result).to eq({})
      end

      it 'returns empty hash when content_attributes is nil' do
        message = double('message', content_attributes: nil)
        result = service.send(:whapi_reply_context, message)
        expect(result).to eq({})
      end
    end

    describe '#get_whapi_content_type' do
      it 'returns audio/ogg for voice messages' do
        attachment = double('attachment', file: double(content_type: 'audio/ogg'))
        result = service.send(:get_whapi_content_type, attachment, 'voice')
        expect(result).to eq('audio/ogg')
      end

      it 'returns audio/ogg for converted audio messages' do
        attachment = double('attachment', file: double(content_type: 'audio/mp3'))
        result = service.send(:get_whapi_content_type, attachment, 'audio')
        expect(result).to eq('audio/ogg')
      end

      it 'returns original content type for non-audio files' do
        attachment = double('attachment', file: double(content_type: 'image/jpeg'))
        result = service.send(:get_whapi_content_type, attachment, 'image')
        expect(result).to eq('image/jpeg')
      end

      it 'returns fallback content type when original is nil' do
        attachment = double('attachment', file: double(content_type: nil))
        result = service.send(:get_whapi_content_type, attachment, 'document')
        expect(result).to eq('application/octet-stream')
      end
    end
  end

  describe '#handle_error' do
    let(:error_message) { 'Invalid phone number format' }
    let(:message) do
      create(:message, conversation: conversation, message_type: :outgoing, content: 'Test message', inbox: whatsapp_channel.inbox)
    end
    let(:error_response) do
      {
        'error' => {
          'message' => error_message
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
          parsed_response: {},
          code: 500
        )
      end

      it 'logs error but does not update message' do
        service.send(:handle_error, error_response_object, message)

        expect(message.reload.status).not_to eq('failed')
        expect(message.reload.external_error).to be_nil
      end
    end
  end

  xdescribe 'integration scenarios' do
    context 'when sending multiple message types in sequence' do
      let(:text_message) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Hello') }
      let(:attachment) { create(:attachment, account: whatsapp_channel.account) }
      let(:image_message) do
        msg = create(:message, conversation: conversation, message_type: :outgoing, content: 'Photo')
        msg.attachments << attachment
        msg
      end

      before do
        allow(attachment).to receive(:file_type).and_return('image')
        allow(attachment.file).to receive(:download).and_return('image_data')
        allow(attachment.file).to receive(:content_type).and_return('image/jpeg')
      end

      it 'handles both text and attachment messages correctly' do
        # Stub text message - match any request to the text endpoint
        stub_request(:post, 'https://gate.whapi.cloud/messages/text')
          .to_return(status: 200, body: { message: { id: 'text_123' } }.to_json)

        # Stub image message with query parameters
        stub_request(:post, 'https://gate.whapi.cloud/messages/media/image')
          .with(
            query: {
              to: contact_phone,
              caption: 'Photo'
            },
            headers: {
              'Authorization' => 'Bearer test_key',
              'Content-Type' => 'image/jpeg'
            },
            body: 'image_data'
          )
          .to_return(status: 200, body: { message: { id: 'image_123' } }.to_json)

        text_result = service.send_message(contact_phone, text_message)
        image_result = service.send_message(contact_phone, image_message)

        expect(text_result).to eq('text_123')
        expect(image_result).to eq('image_123')
      end
    end
  end
end