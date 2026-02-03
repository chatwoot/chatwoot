require 'rails_helper'

RSpec.describe Integrations::Moengage::WebhookProcessorService do
  subject(:service) { described_class.new(hook: hook, payload: payload) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_api, account: account)) }
  let(:webhook_token) { SecureRandom.urlsafe_base64(32) }
  let(:hook) do
    create(:integrations_hook,
           account: account,
           app_id: 'moengage',
           settings: {
             'workspace_id' => 'test-workspace',
             'webhook_token' => webhook_token,
             'default_inbox_id' => inbox.id,
             'auto_create_contact' => true,
             'enable_ai_response' => false
           })
  end

  let(:payload) do
    {
      event_name: 'cart_abandoned',
      triggered_at: Time.current.iso8601,
      customer: {
        customer_id: 'cust_123',
        email: 'test@example.com',
        first_name: 'John',
        last_name: 'Doe',
        phone: '+1234567890'
      },
      event_attributes: {
        cart_value: '$99.00',
        product_name: 'Test Product',
        items_count: 3
      },
      campaign: {
        id: 'campaign_123',
        name: 'Abandoned Cart Recovery'
      }
    }
  end

  describe '#perform' do
    context 'with supported event' do
      it 'creates a new contact' do
        expect { service.perform }.to change(Contact, :count).by(1)
      end

      it 'sets contact attributes correctly' do
        service.perform
        contact = Contact.last

        expect(contact.email).to eq('test@example.com')
        expect(contact.name).to eq('John Doe')
        expect(contact.phone_number).to eq('+1234567890')
        expect(contact.identifier).to eq('cust_123')
      end

      it 'sets moengage custom attributes on contact' do
        service.perform
        contact = Contact.last

        expect(contact.custom_attributes['moengage_customer_id']).to eq('cust_123')
        expect(contact.custom_attributes['source']).to eq('moengage')
      end

      it 'creates a conversation' do
        expect { service.perform }.to change(Conversation, :count).by(1)
      end

      it 'sets conversation custom attributes' do
        service.perform
        conversation = Conversation.last

        expect(conversation.custom_attributes['moengage_event']).to eq('cart_abandoned')
        expect(conversation.custom_attributes['moengage_campaign_id']).to eq('campaign_123')
        expect(conversation.custom_attributes['moengage_campaign_name']).to eq('Abandoned Cart Recovery')
      end

      it 'creates an activity message with event context' do
        service.perform
        conversation = Conversation.last
        message = conversation.messages.activity.last

        expect(message.content).to include('MoEngage Event: Cart Abandoned')
        expect(message.content).to include('Product: Test Product')
        expect(message.content).to include('Cart Value: $99.00')
        expect(message.content).to include('Items: 3')
      end
    end

    context 'with existing contact by email' do
      let!(:existing_contact) do
        create(:contact, account: account, email: 'test@example.com')
      end

      it 'does not create a new contact' do
        expect { service.perform }.not_to change(Contact, :count)
      end

      it 'updates contact custom attributes' do
        service.perform
        existing_contact.reload

        expect(existing_contact.custom_attributes['moengage_customer_id']).to eq('cust_123')
        expect(existing_contact.custom_attributes['last_moengage_event']).to eq('cart_abandoned')
        expect(existing_contact.custom_attributes['last_moengage_event_at']).to be_present
      end

      it 'creates a conversation for existing contact' do
        expect { service.perform }.to change(Conversation, :count).by(1)
      end
    end

    context 'with existing contact by identifier' do
      let!(:existing_contact) do
        create(:contact, account: account, identifier: 'cust_123', email: 'different@example.com')
      end

      it 'finds contact by identifier' do
        expect { service.perform }.not_to change(Contact, :count)
        conversation = Conversation.last
        expect(conversation.contact).to eq(existing_contact)
      end
    end

    context 'with existing contact by phone' do
      let(:payload) do
        {
          event_name: 'cart_abandoned',
          customer: {
            phone: '+1234567890'
          }
        }
      end

      let!(:existing_contact) do
        create(:contact, account: account, phone_number: '+1234567890')
      end

      it 'finds contact by phone number' do
        expect { service.perform }.not_to change(Contact, :count)
        conversation = Conversation.last
        expect(conversation.contact).to eq(existing_contact)
      end
    end

    context 'with existing open conversation' do
      let!(:existing_contact) do
        create(:contact, account: account, email: 'test@example.com', identifier: 'cust_123')
      end

      let!(:contact_inbox) do
        # Use the same source_id that the service would use (identifier || email)
        create(:contact_inbox, contact: existing_contact, inbox: inbox, source_id: 'cust_123')
      end

      let!(:existing_conversation) do
        create(:conversation,
               account: account,
               inbox: inbox,
               contact: existing_contact,
               contact_inbox: contact_inbox,
               status: :open)
      end

      it 'reuses existing open conversation' do
        expect { service.perform }.not_to change(Conversation, :count)
      end

      it 'adds event context message to existing conversation' do
        service.perform
        expect(existing_conversation.messages.activity.count).to eq(1)
      end
    end

    context 'with unsupported event' do
      let(:payload) { { event_name: 'unsupported_event' } }

      it 'does not create contact' do
        expect { service.perform }.not_to change(Contact, :count)
      end

      it 'does not create conversation' do
        expect { service.perform }.not_to change(Conversation, :count)
      end
    end

    context 'with campaign present but no event_name' do
      let(:payload) do
        {
          campaign: { id: 'camp_123', name: 'Test Campaign' },
          customer: { email: 'test@example.com' }
        }
      end

      it 'processes the webhook (campaign presence makes it valid)' do
        expect { service.perform }.to change(Contact, :count).by(1)
      end
    end

    context 'with auto_create_contact disabled' do
      before do
        hook.settings['auto_create_contact'] = false
        hook.save!
      end

      it 'does not create new contact' do
        expect { service.perform }.not_to change(Contact, :count)
      end

      it 'does not create conversation when contact not found' do
        expect { service.perform }.not_to change(Conversation, :count)
      end
    end

    context 'with AI response enabled' do
      let(:agent_bot) { create(:agent_bot, account: account) }

      before do
        hook.settings['enable_ai_response'] = true
        hook.settings['ai_agent_id'] = agent_bot.id
        hook.save!
      end

      it 'assigns agent bot to conversation' do
        service.perform
        conversation = Conversation.last

        expect(conversation.assignee).to be_nil
        expect(conversation.assignee_agent_bot).to eq(agent_bot)
      end
    end

    context 'with different event types' do
      %w[cart_abandoned checkout_abandoned browse_abandoned custom_event campaign_triggered].each do |event|
        it "processes #{event} event" do
          payload[:event_name] = event
          expect { service.perform }.to change(Conversation, :count).by(1)
        end
      end
    end

    context 'with minimal customer data' do
      let(:payload) do
        {
          event_name: 'cart_abandoned',
          customer: {}
        }
      end

      it 'creates contact with default name' do
        service.perform
        contact = Contact.last
        expect(contact.name).to eq('MoEngage Contact')
      end
    end
  end
end
