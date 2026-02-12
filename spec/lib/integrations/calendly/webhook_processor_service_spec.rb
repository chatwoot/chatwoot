require 'rails_helper'

RSpec.describe Integrations::Calendly::WebhookProcessorService do
  let(:account) { create(:account) }
  let(:hook) do
    create(:integrations_hook,
           account: account,
           app_id: 'calendly',
           access_token: 'test-token',
           settings: {
             'calendly_user_uri' => 'https://api.calendly.com/users/ABC123',
             'refresh_token' => 'test-refresh',
             'token_expires_at' => 3.hours.from_now.iso8601,
             'signing_key' => SecureRandom.hex(32)
           })
  end

  let(:event_details) do
    {
      'name' => '30-Minute Demo',
      'start_time' => '2025-06-15T14:00:00Z',
      'end_time' => '2025-06-15T14:30:00Z',
      'status' => 'active'
    }
  end

  before do
    stub_request(:get, %r{api\.calendly\.com/scheduled_events/.*})
      .to_return(status: 200, body: { resource: event_details }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  describe 'invitee.created' do
    let(:payload) do
      {
        'email' => 'customer@example.com',
        'name' => 'Jane Smith',
        'event' => 'https://api.calendly.com/scheduled_events/EV123',
        'status' => 'active',
        'old_invitee' => nil,
        'new_invitee' => nil
      }
    end

    context 'when contact and conversation exist' do
      let!(:contact) { create(:contact, account: account, email: 'customer@example.com') }
      let(:inbox) { create(:inbox, account: account) }
      let!(:conversation) { create(:conversation, account: account, contact: contact, inbox: inbox, status: :open) }

      it 'creates a booking activity message' do
        service = described_class.new(hook: hook, event: 'invitee.created', payload: payload)

        expect { service.perform }.to change(Message, :count).by(1)

        message = conversation.messages.last
        expect(message.content).to include('Meeting booked: 30-Minute Demo')
        expect(message.message_type).to eq('activity')
      end
    end

    context 'when reschedule' do
      let!(:contact) { create(:contact, account: account, email: 'customer@example.com') }
      let(:inbox) { create(:inbox, account: account) }
      let!(:conversation) { create(:conversation, account: account, contact: contact, inbox: inbox, status: :open) }

      it 'creates a reschedule activity message' do
        reschedule_payload = payload.merge('old_invitee' => 'https://api.calendly.com/invitees/OLD123')
        service = described_class.new(hook: hook, event: 'invitee.created', payload: reschedule_payload)

        expect { service.perform }.to change(Message, :count).by(1)

        message = conversation.messages.last
        expect(message.content).to include('Meeting rescheduled: 30-Minute Demo')
      end
    end

    context 'when contact does not exist' do
      it 'creates the contact and handles gracefully if no conversation' do
        service = described_class.new(hook: hook, event: 'invitee.created', payload: payload)
        service.perform

        contact = account.contacts.from_email('customer@example.com')
        expect(contact).to be_present
        expect(contact.name).to eq('Jane Smith')
      end
    end
  end

  describe 'invitee.canceled' do
    let(:payload) do
      {
        'email' => 'customer@example.com',
        'name' => 'Jane Smith',
        'event' => 'https://api.calendly.com/scheduled_events/EV123',
        'status' => 'canceled',
        'old_invitee' => nil,
        'new_invitee' => nil
      }
    end

    context 'when contact and conversation exist' do
      let!(:contact) { create(:contact, account: account, email: 'customer@example.com') }
      let(:inbox) { create(:inbox, account: account) }
      let!(:conversation) { create(:conversation, account: account, contact: contact, inbox: inbox, status: :open) }

      it 'creates a cancellation activity message' do
        service = described_class.new(hook: hook, event: 'invitee.canceled', payload: payload)

        expect { service.perform }.to change(Message, :count).by(1)

        message = conversation.messages.last
        expect(message.content).to include('Meeting canceled: 30-Minute Demo')
      end
    end

    context 'when it is a reschedule cancellation' do
      let(:contact) { create(:contact, account: account, email: 'customer@example.com') }

      it 'skips creating a message' do
        contact # ensure contact exists for the service to find
        reschedule_payload = payload.merge('new_invitee' => 'https://api.calendly.com/invitees/NEW123')
        service = described_class.new(hook: hook, event: 'invitee.canceled', payload: reschedule_payload)

        expect { service.perform }.not_to change(Message, :count)
      end
    end

    context 'when contact does not exist' do
      it 'does not create any message' do
        service = described_class.new(hook: hook, event: 'invitee.canceled', payload: payload)

        expect { service.perform }.not_to change(Message, :count)
      end
    end
  end
end
