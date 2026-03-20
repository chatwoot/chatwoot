require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/groups', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:create_service) { instance_double(Groups::CreateService) }

  before do
    create(:inbox_member, inbox: inbox, user: admin)
    create(:inbox_member, inbox: inbox, user: agent)
    allow(Groups::CreateService).to receive(:new).and_return(create_service)
    allow(create_service).to receive(:perform)
    Channel::WebWidget.define_method(:allow_group_creation?) { true }
  end

  after do
    Channel::WebWidget.remove_method(:allow_group_creation?) if Channel::WebWidget.method_defined?(:allow_group_creation?)
  end

  describe 'POST /api/v1/accounts/{account.id}/groups' do
    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/groups"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      it 'creates a group conversation and returns it' do
        conversation = create(:conversation, account: account, group_type: :group)
        allow(create_service).to receive(:perform).and_return(conversation)

        post "/api/v1/accounts/#{account.id}/groups",
             params: { inbox_id: inbox.id, subject: 'Test Group', participants: ['+5511999999999'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['group_type']).to eq('group')
      end

      it 'returns 422 when provider is unavailable' do
        allow(create_service).to receive(:perform)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Unavailable')

        post "/api/v1/accounts/#{account.id}/groups",
             params: { inbox_id: inbox.id, subject: 'Test Group', participants: [] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Unavailable')
      end

      it 'returns 403 when agent does not have inbox access' do
        other_inbox = create(:inbox, account: account)

        post "/api/v1/accounts/#{account.id}/groups",
             params: { inbox_id: other_inbox.id, subject: 'Test Group', participants: [] },
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body['error']).to be_present
      end
    end
  end
end
