require 'rails_helper'
describe WebhookListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let(:report_identity) { Reports::UpdateAccountIdentity.new(account, Time.zone.now) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end
  let!(:message_created_event) { Events::Base.new(event_name, Time.zone.now, message: message) }
  let!(:conversation_created_event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }
  let!(:contact_event) { Events::Base.new(event_name, Time.zone.now, contact: contact) }

  describe '#message_created' do
    let(:event_name) { :'message.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.message_created(message_created_event)
      end
    end

    context 'when webhook is configured and event is subscribed' do
      it 'triggers the webhook event' do
        webhook = create(:webhook, inbox: inbox, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, message.webhook_data.merge(event: 'message_created')).once
        listener.message_created(message_created_event)
      end
    end

    context 'when webhook is configured and event is not subscribed' do
      it 'does not trigger the webhook event' do
        create(:webhook, subscriptions: ['conversation_created'], inbox: inbox, account: account)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.message_created(message_created_event)
      end
    end

    context 'when inbox is an API Channel' do
      it 'triggers webhook if webhook_url is present' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_message = create(
          :message,
          message_type: 'outgoing',
          account: account,
          inbox: api_inbox,
          conversation: api_conversation
        )
        api_event = Events::Base.new(event_name, Time.zone.now, message: api_message)
        expect(WebhookJob).to receive(:perform_later).with(channel_api.webhook_url, api_message.webhook_data.merge(event: 'message_created'),
                                                           :api_inbox_webhook).once
        listener.message_created(api_event)
      end

      it 'does not trigger webhook if webhook_url is not present' do
        channel_api = create(:channel_api, webhook_url: nil, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_message = create(
          :message,
          message_type: 'outgoing',
          account: account,
          inbox: channel_api.inbox,
          conversation: api_conversation
        )
        api_event = Events::Base.new(event_name, Time.zone.now, message: api_message)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.message_created(api_event)
      end
    end
  end

  describe '#conversation_created' do
    let(:event_name) { :'conversation.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.conversation_created(conversation_created_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, conversation.webhook_data.merge(event: 'conversation_created')).once
        listener.conversation_created(conversation_created_event)
      end
    end

    context 'when inbox is an API Channel' do
      it 'triggers webhook if webhook_url is present' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_event = Events::Base.new(event_name, Time.zone.now, conversation: api_conversation)
        expect(WebhookJob).to receive(:perform_later).with(channel_api.webhook_url,
                                                           api_conversation.webhook_data.merge(event: 'conversation_created'),
                                                           :api_inbox_webhook).once
        listener.conversation_created(api_event)
      end

      it 'does not trigger webhook if webhook_url is not present' do
        channel_api = create(:channel_api, webhook_url: nil, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_event = Events::Base.new(event_name, Time.zone.now, conversation: api_conversation)
        expect(WebhookJob).not_to receive(:perform_later)
        listener.conversation_created(api_event)
      end
    end
  end

  describe '#conversation_updated' do
    let(:custom_attributes) { { test: nil } }
    let!(:conversation_updated_event) do
      Events::Base.new(
        event_name, Time.zone.now,
        conversation: conversation.reload,
        changed_attributes: {
          custom_attributes: [{ test: nil }, { test: 'testing custom attri webhook' }]
        }
      )
    end
    let(:event_name) { :'conversation.updated' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.conversation_updated(conversation_updated_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)

        conversation.update(custom_attributes: { test: 'testing custom attri webhook' })

        expect(WebhookJob).to receive(:perform_later).with(
          webhook.url,
          conversation.webhook_data.merge(
            event: 'conversation_updated',
            changed_attributes: [
              {
                custom_attributes: {
                  previous_value: { test: nil },
                  current_value: { test: 'testing custom attri webhook' }
                }
              }
            ]
          )
        ).once

        listener.conversation_updated(conversation_updated_event)
      end
    end
  end

  describe '#contact_created' do
    let(:event_name) { :'contact.created' }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.contact_created(contact_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, account: account)
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, contact.webhook_data.merge(event: 'contact_created')).once
        listener.contact_created(contact_event)
      end
    end
  end

  describe '#contact_updated' do
    let(:event_name) { :'contact.updated' }
    let!(:contact_updated_event) { Events::Base.new(event_name, Time.zone.now, contact: contact, changed_attributes: changed_attributes) }
    let(:changed_attributes) { { 'name' => ['Jane', 'Jane Doe'] } }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.contact_updated(contact_updated_event)
      end
    end

    context 'when webhook is configured and there is no changed attributes' do
      let(:changed_attributes) { {} }

      it 'triggers webhook' do
        create(:webhook, account: account)
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.contact_updated(contact_updated_event)
      end
    end

    context 'when webhook is configured and there are changed attributes' do
      it 'triggers webhook' do
        webhook = create(:webhook, account: account)
        expect(WebhookJob).to receive(:perform_later).with(
          webhook.url,
          contact.webhook_data.merge(
            event: 'contact_updated',
            changed_attributes: [{ 'name' => { :current_value => 'Jane Doe', :previous_value => 'Jane' } }]
          )
        ).once
        listener.contact_updated(contact_updated_event)
      end
    end
  end

  describe '#inbox_created' do
    let(:event_name) { :'inbox.created' }
    let!(:inbox_created_event) { Events::Base.new(event_name, Time.zone.now, inbox: inbox) }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.inbox_created(inbox_created_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        inbox_data = Inbox::EventDataPresenter.new(inbox).push_data
        webhook = create(:webhook, account: account, subscriptions: ['inbox_created'])
        expect(WebhookJob).to receive(:perform_later).with(webhook.url, inbox_data.merge(event: 'inbox_created')).once
        listener.inbox_created(inbox_created_event)
      end
    end
  end

  describe '#inbox_updated' do
    let(:event_name) { :'inbox.updated' }
    let!(:inbox_updated_event) { Events::Base.new(event_name, Time.zone.now, inbox: inbox, changed_attributes: changed_attributes) }
    let(:changed_attributes) { {} }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.inbox_updated(inbox_updated_event)
      end
    end

    context 'when webhook is configured and there are no changed attributes' do
      it 'triggers webhook' do
        create(:webhook, account: account, subscriptions: ['inbox_updated'])
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.inbox_updated(inbox_updated_event)
      end
    end

    context 'when webhook is configured' do
      let(:changed_attributes) { { 'name' => ['Inbox 1', inbox.name] } }

      it 'triggers webhook' do
        webhook = create(:webhook, account: account, subscriptions: ['inbox_updated'])

        inbox_data = Inbox::EventDataPresenter.new(inbox).push_data
        changed_attributes_data = [{ 'name' => { 'previous_value': 'Inbox 1', 'current_value': inbox.name } }]

        expect(WebhookJob).to receive(:perform_later).with(
          webhook.url,
          inbox_data.merge(event: 'inbox_updated', changed_attributes: changed_attributes_data)
        ).once

        listener.inbox_updated(inbox_updated_event)
      end
    end
  end

  describe '#conversation_typing_on' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:typing_event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: user) }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).not_to receive(:perform_later)
        listener.conversation_typing_on(typing_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account, subscriptions: ['conversation_typing_on'])

        payload = {
          event: 'conversation_typing_on',
          user: user.webhook_data,
          conversation: conversation.webhook_data,
          is_private: false
        }

        expect(WebhookJob).to receive(:perform_later).with(webhook.url, payload).once
        listener.conversation_typing_on(typing_event)
      end
    end

    context 'when inbox is an API Channel' do
      it 'triggers webhook if webhook_url is present' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_event = Events::Base.new(event_name, Time.zone.now, conversation: api_conversation, user: user, is_private: false)

        payload = {
          event: 'conversation_typing_on',
          user: user.webhook_data,
          conversation: api_conversation.webhook_data,
          is_private: false
        }

        expect(WebhookJob).to receive(:perform_later).with(channel_api.webhook_url, payload, :api_inbox_webhook).once
        listener.conversation_typing_on(api_event)
      end
    end
  end

  describe '#conversation_typing_off' do
    let(:event_name) { :'conversation.typing_off' }
    let!(:typing_event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: user, is_private: false) }

    context 'when webhook is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).not_to receive(:perform_later)
        listener.conversation_typing_off(typing_event)
      end
    end

    context 'when webhook is configured' do
      it 'triggers webhook' do
        webhook = create(:webhook, inbox: inbox, account: account, subscriptions: ['conversation_typing_off'])

        payload = {
          event: 'conversation_typing_off',
          user: user.webhook_data,
          conversation: conversation.webhook_data,
          is_private: false
        }

        expect(WebhookJob).to receive(:perform_later).with(webhook.url, payload).once
        listener.conversation_typing_off(typing_event)
      end
    end
  end

  describe 'SocialWise integration' do
    let(:event_name) { :'message.created' }

    context 'when SocialWise is not active' do
      it 'delivers webhook without socialwise-chatwit data' do
        webhook = create(:webhook, inbox: inbox, account: account)
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(url).to eq(webhook.url)
          expect(payload).not_to have_key('socialwise-chatwit')
          expect(payload[:event]).to eq('message_created')
        end
        
        listener.message_created(message_created_event)
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

      it 'delivers webhook with socialwise-chatwit data' do
        webhook = create(:webhook, inbox: inbox, account: account)
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(url).to eq(webhook.url)
          expect(payload).to have_key('socialwise-chatwit')
          expect(payload['socialwise-chatwit']).to be_a(Hash)
          expect(payload['socialwise-chatwit']).to include(
            'whatsapp_identifiers',
            'contact_data',
            'conversation_data',
            'message_data',
            'inbox_data',
            'account_data',
            'metadata',
            'whatsapp_api_key'
          )
          expect(payload[:event]).to eq('message_created')
        end
        
        listener.message_created(message_created_event)
      end

      it 'includes SocialWise metadata in webhook payload' do
        webhook = create(:webhook, inbox: inbox, account: account)
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          metadata = payload['socialwise-chatwit']['metadata']
          expect(metadata['socialwise_active']).to be true
          expect(metadata['payload_version']).to eq('2.0')
          expect(metadata['timestamp']).to be_present
        end
        
        listener.message_created(message_created_event)
      end

      context 'when webhook has ACCESS_TOKEN enabled' do
        it 'includes both ACCESS_TOKEN and socialwise-chatwit data' do
          administrator = create(:user, account: account, role: 'administrator')
          access_token = create(:access_token, resource_owner_id: administrator.id)
          webhook = create(:webhook, inbox: inbox, account: account, include_access_token: true)
          
          expect(WebhookJob).to receive(:perform_later) do |url, payload|
            expect(payload).to have_key(:ACCESS_TOKEN)
            expect(payload).to have_key('socialwise-chatwit')
            expect(payload[:ACCESS_TOKEN]).to eq(access_token.token)
            expect(payload['socialwise-chatwit']['metadata']['socialwise_active']).to be true
          end
          
          listener.message_created(message_created_event)
        end
      end

      context 'when SocialWise enhancement fails' do
        it 'continues webhook delivery with original payload' do
          webhook = create(:webhook, inbox: inbox, account: account)
          
          # Mock SocialWise service to raise error
          allow(Integrations::Socialwise::WebhookEnhancerService).to receive(:enhance_payload).and_raise(StandardError, 'Enhancement failed')
          
          expect(WebhookJob).to receive(:perform_later) do |url, payload|
            expect(url).to eq(webhook.url)
            expect(payload).not_to have_key('socialwise-chatwit')
            expect(payload[:event]).to eq('message_created')
          end
          
          listener.message_created(message_created_event)
        end
      end
    end

    context 'when inbox is API Channel with SocialWise active' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'includes SocialWise data in API inbox webhook' do
        channel_api = create(:channel_api, account: account)
        api_inbox = channel_api.inbox
        api_conversation = create(:conversation, account: account, inbox: api_inbox, assignee: user)
        api_message = create(
          :message,
          message_type: 'outgoing',
          account: account,
          inbox: api_inbox,
          conversation: api_conversation
        )
        api_event = Events::Base.new(event_name, Time.zone.now, message: api_message)
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload, webhook_type|
          expect(url).to eq(channel_api.webhook_url)
          expect(webhook_type).to eq(:api_inbox_webhook)
          expect(payload).to have_key('socialwise-chatwit')
          expect(payload['socialwise-chatwit']['metadata']['socialwise_active']).to be true
        end
        
        listener.message_created(api_event)
      end
    end

    context 'when WhatsApp channel with API key' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: { 'api_key' => 'test_whatsapp_key_123' }) }
      let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
      let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, assignee: user) }
      let(:whatsapp_message) do
        create(:message, message_type: 'outgoing',
                         account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation)
      end
      let(:whatsapp_event) { Events::Base.new(event_name, Time.zone.now, message: whatsapp_message) }

      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'includes WhatsApp API key in socialwise-chatwit data' do
        webhook = create(:webhook, inbox: whatsapp_inbox, account: account)
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(payload['socialwise-chatwit']['whatsapp_api_key']).to eq('test_whatsapp_key_123')
          expect(payload['socialwise-chatwit']['metadata']['has_whatsapp_api_key']).to be true
          expect(payload['socialwise-chatwit']['metadata']['is_whatsapp_channel']).to be true
        end
        
        listener.message_created(whatsapp_event)
      end
    end

    context 'for different webhook event types' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'includes SocialWise data in conversation_created webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(payload).to have_key('socialwise-chatwit')
          expect(payload[:event]).to eq('conversation_created')
        end
        
        listener.conversation_created(conversation_created_event)
      end

      it 'includes SocialWise data in contact_created webhook' do
        webhook = create(:webhook, account: account)
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(payload).to have_key('socialwise-chatwit')
          expect(payload[:event]).to eq('contact_created')
        end
        
        listener.contact_created(contact_event)
      end

      it 'includes SocialWise data in conversation_updated webhook' do
        webhook = create(:webhook, inbox: inbox, account: account)
        conversation_updated_event = Events::Base.new(
          :'conversation.updated', Time.zone.now,
          conversation: conversation.reload,
          changed_attributes: { status: ['open', 'resolved'] }
        )
        
        expect(WebhookJob).to receive(:perform_later) do |url, payload|
          expect(payload).to have_key('socialwise-chatwit')
          expect(payload[:event]).to eq('conversation_updated')
        end
        
        listener.conversation_updated(conversation_updated_event)
      end
    end
  end
end
