require 'rails_helper'

RSpec.describe 'Conversation Payment Links API', type: :request do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let!(:contact) { conversation.contact }

  before do
    contact.update(
      name: 'John Doe',
      email: 'john@example.com',
      phone_number: '+96512345678'
    )
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/payment_links' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        )

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)

        # Set up payment provider configuration for the account
        AccountPayzahSettings.create!(account: account, enabled: true, api_key: 'test_api_key')

        # Stub Payzah service to avoid real API calls
        allow_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:perform).and_return(
          {
            'transit_url' => 'https://example.com/pay/123',
            'PaymentID' => 'PAY123'
          }
        )
      end

      it 'creates a payment link and sends message to conversation' do
        params = { amount: 100.50, currency: 'KWD' }

        expect do
          post api_v1_account_conversation_payment_links_url(
            account_id: account.id,
            conversation_id: conversation.display_id
          ),
               params: params,
               headers: agent.create_new_auth_token,
               as: :json
        end.to change(conversation.messages, :count).by(1)

        expect(response).to have_http_status(:created)

        json_response = response.parsed_body
        expect(json_response['success']).to be(true)
        expect(json_response['data']['payment_url']).to eq('https://example.com/pay/123')
        expect(json_response['data']['amount'].to_f).to eq(100.50)
        expect(json_response['data']['currency']).to eq('KWD')
        expect(json_response['data']['provider']).to eq('payzah')

        # Check message content
        message = conversation.messages.last
        expect(message.content).to include('100.5 KWD')
        expect(message.content).to include('https://example.com/pay/123')
      end

      it 'uses contact data for customer information' do
        params = { amount: 75, currency: 'SAR' }

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)

        # Verify the payment link was created with contact data
        payment_link = PaymentLink.last
        expect(payment_link.payload['customer_data']['name']).to eq('John Doe')
        expect(payment_link.payload['customer_data']['email']).to eq('john@example.com')
        expect(payment_link.payload['customer_data']['phone']).to eq('+96512345678')
      end

      it 'returns error when amount is missing' do
        params = { currency: 'KWD' }

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to include('Amount')
      end

      it 'returns error when currency is missing' do
        params = { amount: 100 }

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to include('Currency')
      end

      it 'handles Payzah service errors gracefully' do
        allow_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:perform).and_raise(
          StandardError.new('Payzah API error')
        )

        params = { amount: 100, currency: 'KWD' }

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Payzah API error')
      end
    end

    context 'when user does not have access to conversation' do
      let(:other_agent) { create(:user, account: account, role: :agent) }

      before do
        # Set up payment provider configuration for the account
        AccountPayzahSettings.create!(account: account, enabled: true, api_key: 'test_api_key')

        # Stub Payzah service to avoid real API calls
        allow_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:perform).and_return(
          {
            'transit_url' => 'https://example.com/pay/123',
            'PaymentID' => 'PAY123'
          }
        )
      end

      it 'allows creating payment links (agents have full access)' do
        params = { amount: 100, currency: 'KWD' }

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: other_agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end
    end
  end
end
