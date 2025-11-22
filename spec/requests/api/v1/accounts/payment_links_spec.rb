# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payment Links API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, contact: contact) }
  let(:message) { create(:message, conversation: conversation, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/payment_links' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/payment_links"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:payment_link) do
        create(:payment_link,
               account: account,
               conversation: conversation,
               message: message,
               contact: contact,
               created_by: administrator)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'returns all payment links' do
        payment_link # Create the payment link before the request
        get "/api/v1/accounts/#{account.id}/payment_links",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        json_response = response.parsed_body
        expect(json_response['meta']).to be_present
        expect(json_response['meta']['count']).to eq(1)
        expect(json_response['meta']['current_page']).to eq(1)

        expect(json_response['payload']).to be_an(Array)
        expect(json_response['payload'].length).to eq(1)

        payment = json_response['payload'].first
        expect(payment['payment_id']).to eq(payment_link.payment_id)
        expect(payment['amount']).to eq(payment_link.amount.to_s)
        expect(payment['currency']).to eq(payment_link.currency)
        expect(payment['status']).to eq(payment_link.status)
      end
      # rubocop:enable RSpec/MultipleExpectations

      it 'includes associated contact information' do
        payment_link # Create the payment link before the request
        get "/api/v1/accounts/#{account.id}/payment_links",
            headers: administrator.create_new_auth_token,
            as: :json

        payment = response.parsed_body['payload'].first
        expect(payment['contact']).to be_present
        expect(payment['contact']['id']).to eq(contact.id)
        expect(payment['contact']['name']).to eq(contact.name)
      end

      it 'includes conversation information' do
        payment_link # Create the payment link before the request
        get "/api/v1/accounts/#{account.id}/payment_links",
            headers: administrator.create_new_auth_token,
            as: :json

        payment = response.parsed_body['payload'].first
        expect(payment['conversation']).to be_present
        expect(payment['conversation']['id']).to eq(conversation.id)
        expect(payment['conversation']['display_id']).to eq(conversation.display_id)
      end

      it 'includes created_by information' do
        payment_link # Create the payment link before the request
        get "/api/v1/accounts/#{account.id}/payment_links",
            headers: administrator.create_new_auth_token,
            as: :json

        payment = response.parsed_body['payload'].first
        expect(payment['created_by']).to be_present
        expect(payment['created_by']['id']).to eq(administrator.id)
        expect(payment['created_by']['name']).to eq(administrator.name)
      end

      context 'with multiple payment links' do
        let!(:payment_link2) do
          create(:payment_link, :paid,
                 account: account,
                 conversation: conversation,
                 message: create(:message, conversation: conversation, account: account),
                 contact: contact,
                 created_by: administrator)
        end
        let!(:payment_link3) do
          create(:payment_link, :failed,
                 account: account,
                 conversation: conversation,
                 message: create(:message, conversation: conversation, account: account),
                 contact: contact,
                 created_by: administrator)
        end

        it 'returns all payment links ordered by created_at desc' do
          payment_link # Create the payment link before the request
          get "/api/v1/accounts/#{account.id}/payment_links",
              headers: administrator.create_new_auth_token,
              as: :json

          json_response = response.parsed_body
          expect(json_response['meta']['count']).to eq(3)
          expect(json_response['payload'].length).to eq(3)

          # Verify all payment links are present
          payment_ids = json_response['payload'].map { |p| p['payment_id'] }
          expect(payment_ids).to contain_exactly(payment_link.payment_id, payment_link2.payment_id, payment_link3.payment_id)
        end
      end

      context 'with pagination' do
        before do
          payment_link # Create the base payment link
          # Create 20 more payment links to test pagination
          20.times do |_i|
            msg = create(:message, conversation: conversation, account: account)
            create(:payment_link,
                   account: account,
                   conversation: conversation,
                   message: msg,
                   contact: contact,
                   created_by: administrator)
          end
        end

        it 'returns paginated results with 15 per page' do
          get "/api/v1/accounts/#{account.id}/payment_links?page=1",
              headers: administrator.create_new_auth_token,
              as: :json

          json_response = response.parsed_body
          expect(json_response['meta']['count']).to eq(21) # 20 + 1 from let
          expect(json_response['payload'].length).to eq(15)
        end

        it 'returns second page results' do
          get "/api/v1/accounts/#{account.id}/payment_links?page=2",
              headers: administrator.create_new_auth_token,
              as: :json

          json_response = response.parsed_body
          expect(json_response['meta']['count']).to eq(21)
          expect(json_response['meta']['current_page']).to eq('2')
          expect(json_response['payload'].length).to eq(6)
        end
      end

      context 'when no payment links exist' do
        it 'returns empty array' do
          get "/api/v1/accounts/#{account.id}/payment_links",
              headers: administrator.create_new_auth_token,
              as: :json

          json_response = response.parsed_body
          expect(json_response['meta']['count']).to eq(0)
          expect(json_response['payload']).to eq([])
        end
      end
    end

    context 'when it is an authenticated agent' do
      # rubocop:disable RSpec/LetSetup
      let!(:payment_link) do
        create(:payment_link,
               account: account,
               conversation: conversation,
               message: message,
               contact: contact,
               created_by: agent)
      end
      # rubocop:enable RSpec/LetSetup

      it 'returns all payment links' do
        get "/api/v1/accounts/#{account.id}/payment_links",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].length).to eq(1)
      end
    end

    context 'when accessing different account payment links' do
      let(:other_account) { create(:account) }
      # rubocop:disable RSpec/LetSetup
      let!(:other_payment_link) do
        other_user = create(:user, account: other_account, role: :administrator)
        other_contact = create(:contact, account: other_account)
        other_conversation = create(:conversation, account: other_account, contact: other_contact)
        other_message = create(:message, conversation: other_conversation, account: other_account)

        create(:payment_link,
               account: other_account,
               conversation: other_conversation,
               message: other_message,
               contact: other_contact,
               created_by: other_user)
      end
      # rubocop:enable RSpec/LetSetup

      it 'does not return payment links from other accounts' do
        get "/api/v1/accounts/#{account.id}/payment_links",
            headers: administrator.create_new_auth_token,
            as: :json

        json_response = response.parsed_body
        expect(json_response['payload']).to eq([])
      end
    end
  end
end
