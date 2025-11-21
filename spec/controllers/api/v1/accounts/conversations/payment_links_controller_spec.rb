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

        # Stub Payzah service to avoid real API calls
        allow_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:perform).and_return(
          {
            payment_url: 'https://example.com/pay/123',
            payment_id: 'PAY123',
            direct_url: 'https://example.com/direct/123',
            gateway_url: 'https://example.com/gateway'
          }
        )
      end

      it 'creates a payment link and sends message to conversation' do
        params = {
          amount: 100.50,
          currency: 'KWD',
          customer: {
            name: 'John Doe',
            email: 'john@example.com',
            phone: '+96512345678'
          }
        }

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
        expect(json_response['data']['payment_id']).to eq('PAY123')
        expect(json_response['data']['amount']).to eq(100.50)
        expect(json_response['data']['currency']).to eq('KWD')

        # Check message content
        message = conversation.messages.last
        expect(message.content).to include('100.5 KWD')
        expect(message.content).to include('https://example.com/pay/123')
      end

      it 'uses conversation display_id as trackid' do
        params = { amount: 50, currency: 'USD' }

        expect_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:initialize).with(
          hash_including(trackid: conversation.display_id)
        ).and_call_original

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json
      end

      it 'falls back to contact data when customer params are empty' do
        params = { amount: 75, currency: 'SAR', customer: {} }

        expect_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:initialize).with(
          hash_including(
            customer: {
              name: 'John Doe',
              email: 'john@example.com',
              phone: '+96512345678'
            }
          )
        ).and_call_original

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'uses customer params when provided' do
        params = {
          amount: 25,
          currency: 'AED',
          customer: {
            name: 'Jane Smith',
            email: 'jane@example.com',
            phone: '+96587654321'
          }
        }

        expect_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:initialize).with(
          hash_including(
            customer: {
              name: 'Jane Smith',
              email: 'jane@example.com',
              phone: '+96587654321'
            }
          )
        ).and_call_original

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'returns error when amount is missing' do
        # Mock service to raise validation error
        allow_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:perform).and_raise(
          ArgumentError.new('Amount is required')
        )

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
        expect(json_response['error']).to eq('Amount is required')
      end

      it 'returns error when currency is missing' do
        # Mock service to raise validation error
        allow_any_instance_of(Payzah::CreatePaymentLinkService).to receive(:perform).and_raise(
          ArgumentError.new('Currency is required')
        )

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
        expect(json_response['error']).to eq('Currency is required')
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

      it 'returns unauthorized' do
        params = { amount: 100, currency: 'KWD' }

        post api_v1_account_conversation_payment_links_url(
          account_id: account.id,
          conversation_id: conversation.display_id
        ),
             params: params,
             headers: other_agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
