require 'rails_helper'

RSpec.describe 'SocialWise Webhook Integration', type: :integration do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }
  let(:webhook) { create(:webhook, inbox: inbox, account: account) }

  describe 'End-to-end webhook flow with SocialWise enhancement' do
    context 'when SocialWise is not active' do
      it 'delivers standard webhook without socialwise-chatwit data' do
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(url).to eq(webhook.url)
          expect(payload).not_to have_key('socialwise-chatwit')
          expect(payload[:event]).to eq('message_created')
          expect(payload[:message]).to be_present
          expect(payload[:conversation]).to be_present
          expect(payload[:contact]).to be_present
        end

        # Trigger the event that should cause webhook delivery
        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'message.created', Time.zone.now, message: message)
        )
      end
    end

    context 'when SocialWise is active' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'delivers enhanced webhook with complete socialwise-chatwit data structure' do
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(url).to eq(webhook.url)
          expect(payload[:event]).to eq('message_created')
          
          # Verify socialwise-chatwit data is present and complete
          socialwise_data = payload['socialwise-chatwit']
          expect(socialwise_data).to be_present
          
          # Verify all required sections are present
          expect(socialwise_data).to include(
            'whatsapp_identifiers',
            'contact_data',
            'conversation_data',
            'message_data',
            'inbox_data',
            'account_data',
            'metadata',
            'whatsapp_api_key'
          )
          
          # Verify data integrity
          expect(socialwise_data['contact_data']['id']).to eq(contact.id)
          expect(socialwise_data['conversation_data']['id']).to eq(conversation.id)
          expect(socialwise_data['message_data']['id']).to eq(message.id)
          expect(socialwise_data['inbox_data']['id']).to eq(inbox.id)
          expect(socialwise_data['account_data']['id']).to eq(account.id)
          
          # Verify metadata
          expect(socialwise_data['metadata']['socialwise_active']).to be true
          expect(socialwise_data['metadata']['payload_version']).to eq('2.0')
          expect(socialwise_data['metadata']['timestamp']).to be_present
        end

        # Trigger the event
        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'message.created', Time.zone.now, message: message)
        )
      end

      it 'handles multiple webhook types with SocialWise enhancement' do
        webhook_calls = []
        
        allow(WebhookJob).to receive(:perform_later) do |url, payload|
          webhook_calls << { url: url, payload: payload }
        end

        # Trigger multiple different events
        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'message.created', Time.zone.now, message: message)
        )
        
        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'conversation.created', Time.zone.now, conversation: conversation)
        )
        
        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'contact.created', Time.zone.now, contact: contact)
        )

        expect(webhook_calls.length).to eq(3)
        
        # Verify each webhook call has SocialWise data
        webhook_calls.each do |call|
          expect(call[:payload]).to have_key('socialwise-chatwit')
          expect(call[:payload]['socialwise-chatwit']['metadata']['socialwise_active']).to be true
        end
        
        # Verify event types
        events = webhook_calls.map { |call| call[:payload][:event] }
        expect(events).to contain_exactly('message_created', 'conversation_created', 'contact_created')
      end

      context 'with ACCESS_TOKEN enabled' do
        let(:administrator) { create(:user, account: account, role: 'administrator') }
        let(:access_token) { create(:access_token, resource_owner_id: administrator.id) }
        let(:webhook_with_token) { create(:webhook, inbox: inbox, account: account, include_access_token: true) }

        it 'includes both ACCESS_TOKEN and socialwise-chatwit data' do
          expect(WebhookJob).to receive(:perform_later) do |url, payload|
            expect(payload).to have_key(:ACCESS_TOKEN)
            expect(payload).to have_key('socialwise-chatwit')
            expect(payload[:ACCESS_TOKEN]).to eq(access_token.token)
            expect(payload['socialwise-chatwit']['metadata']['socialwise_active']).to be true
          end

          Rails.application.config.dispatcher.dispatch(
            Events::Base.new(:'message.created', Time.zone.now, message: message)
          )
        end
      end

      context 'with WhatsApp channel and API key' do
        let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: { 'api_key' => 'test_api_key_e2e' }) }
        let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
        let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
        let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation, source_id: 'wamid.test123') }
        let(:whatsapp_webhook) { create(:webhook, inbox: whatsapp_inbox, account: account) }

        it 'includes WhatsApp API key and proper identifiers in webhook payload' do
          expect(WebhookJob).to receive(:perform_later) do |url, payload|
            socialwise_data = payload['socialwise-chatwit']
            
            expect(socialwise_data['whatsapp_api_key']).to eq('test_api_key_e2e')
            expect(socialwise_data['metadata']['has_whatsapp_api_key']).to be true
            expect(socialwise_data['metadata']['is_whatsapp_channel']).to be true
            
            expect(socialwise_data['whatsapp_identifiers']['wamid']).to eq('wamid.test123')
            expect(socialwise_data['whatsapp_identifiers']['whatsapp_id']).to eq('wamid.test123')
          end

          Rails.application.config.dispatcher.dispatch(
            Events::Base.new(:'message.created', Time.zone.now, message: whatsapp_message)
          )
        end
      end

      context 'with API inbox webhook' do
        let(:channel_api) { create(:channel_api, account: account) }
        let(:api_inbox) { channel_api.inbox }
        let(:api_conversation) { create(:conversation, account: account, inbox: api_inbox, contact: contact) }
        let(:api_message) { create(:message, account: account, inbox: api_inbox, conversation: api_conversation) }

        it 'includes SocialWise data in API inbox webhook delivery' do
          expect(WebhookJob).to receive(:perform_later) do |url, payload, webhook_type|
            expect(url).to eq(channel_api.webhook_url)
            expect(webhook_type).to eq(:api_inbox_webhook)
            expect(payload).to have_key('socialwise-chatwit')
            expect(payload['socialwise-chatwit']['metadata']['socialwise_active']).to be true
          end

          Rails.application.config.dispatcher.dispatch(
            Events::Base.new(:'message.created', Time.zone.now, message: api_message)
          )
        end
      end
    end

    context 'when SocialWise enhancement fails' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'continues webhook delivery with original payload when enhancement fails' do
        # Mock the SocialWise service to fail
        allow(Integrations::Socialwise::WebhookEnhancerService).to receive(:enhance_payload).and_raise(StandardError, 'Enhancement failed')

        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(url).to eq(webhook.url)
          expect(payload[:event]).to eq('message_created')
          expect(payload).not_to have_key('socialwise-chatwit')
          # Original webhook data should still be present
          expect(payload[:message]).to be_present
          expect(payload[:conversation]).to be_present
        end

        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'message.created', Time.zone.now, message: message)
        )
      end
    end

    context 'webhook payload validation' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'validates complete socialwise-chatwit data structure' do
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          socialwise_data = payload['socialwise-chatwit']
          
          # Validate whatsapp_identifiers structure
          expect(socialwise_data['whatsapp_identifiers']).to include('wamid', 'whatsapp_id', 'contact_source')
          
          # Validate contact_data structure
          contact_data = socialwise_data['contact_data']
          expect(contact_data).to include('id', 'name', 'phone_number', 'email', 'identifier', 'custom_attributes')
          expect(contact_data['custom_attributes']).to be_a(Hash)
          
          # Validate conversation_data structure
          conversation_data = socialwise_data['conversation_data']
          expect(conversation_data).to include('id', 'status', 'assignee_id', 'created_at', 'updated_at')
          
          # Validate message_data structure
          message_data = socialwise_data['message_data']
          expect(message_data).to include('id', 'content', 'content_type', 'message_type', 'created_at')
          
          # Validate inbox_data structure
          inbox_data = socialwise_data['inbox_data']
          expect(inbox_data).to include('id', 'name', 'channel_type')
          
          # Validate account_data structure
          account_data = socialwise_data['account_data']
          expect(account_data).to include('id', 'name')
          
          # Validate metadata structure
          metadata = socialwise_data['metadata']
          expect(metadata).to include('socialwise_active', 'is_whatsapp_channel', 'payload_version', 'timestamp', 'has_whatsapp_api_key')
          expect(metadata['socialwise_active']).to be true
          expect(metadata['payload_version']).to eq('2.0')
          
          # Validate whatsapp_api_key field exists
          expect(socialwise_data).to have_key('whatsapp_api_key')
        end

        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'message.created', Time.zone.now, message: message)
        )
      end

      it 'validates data types and formats' do
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          socialwise_data = payload['socialwise-chatwit']
          
          # Validate ID fields are integers
          expect(socialwise_data['contact_data']['id']).to be_a(Integer)
          expect(socialwise_data['conversation_data']['id']).to be_a(Integer)
          expect(socialwise_data['message_data']['id']).to be_a(Integer)
          expect(socialwise_data['inbox_data']['id']).to be_a(Integer)
          expect(socialwise_data['account_data']['id']).to be_a(Integer)
          
          # Validate timestamp formats
          expect(socialwise_data['conversation_data']['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
          expect(socialwise_data['metadata']['timestamp']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
          
          # Validate boolean fields
          expect(socialwise_data['metadata']['socialwise_active']).to be_a(TrueClass)
          expect([TrueClass, FalseClass]).to include(socialwise_data['metadata']['is_whatsapp_channel'].class)
          expect([TrueClass, FalseClass]).to include(socialwise_data['metadata']['has_whatsapp_api_key'].class)
        end

        Rails.application.config.dispatcher.dispatch(
          Events::Base.new(:'message.created', Time.zone.now, message: message)
        )
      end
    end

    context 'performance with enhanced payloads' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'delivers webhooks within acceptable time limits' do
        webhook_calls = []
        
        allow(WebhookJob).to receive(:perform_later) do |url, payload|
          webhook_calls << { url: url, payload: payload }
        end

        # Measure time for multiple webhook deliveries
        start_time = Time.current
        
        10.times do |i|
          test_message = create(:message, account: account, inbox: inbox, conversation: conversation, content: "Test message #{i}")
          Rails.application.config.dispatcher.dispatch(
            Events::Base.new(:'message.created', Time.zone.now, message: test_message)
          )
        end
        
        end_time = Time.current
        total_time = end_time - start_time
        
        expect(webhook_calls.length).to eq(10)
        expect(total_time).to be < 5.seconds # Should complete within 5 seconds
        
        # Verify all webhooks have SocialWise data
        webhook_calls.each do |call|
          expect(call[:payload]).to have_key('socialwise-chatwit')
        end
      end
    end
  end
end