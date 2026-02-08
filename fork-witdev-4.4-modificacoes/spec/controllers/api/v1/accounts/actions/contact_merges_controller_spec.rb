require 'rails_helper'

RSpec.describe 'Contact Merge Action API', type: :request do
  let(:account) { create(:account) }
  let!(:base_contact) { create(:contact, account: account) }
  let!(:mergee_contact) { create(:contact, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/actions/contact_merge' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/actions/contact_merge"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:merge_action) { double }

      before do
        allow(ContactMergeAction).to receive(:new).and_return(merge_action)
        allow(merge_action).to receive(:perform)
      end

      it 'merges two contacts by calling contact merge action' do
        post "/api/v1/accounts/#{account.id}/actions/contact_merge",
             params: { base_contact_id: base_contact.id, mergee_contact_id: mergee_contact.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(base_contact.id)
        expected_params = { account: account, base_contact: base_contact, mergee_contact: mergee_contact }
        expect(ContactMergeAction).to have_received(:new).with(expected_params)
        expect(merge_action).to have_received(:perform)
      end
    end
  end
end
