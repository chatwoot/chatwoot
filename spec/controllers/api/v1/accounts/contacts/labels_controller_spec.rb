require 'rails_helper'

RSpec.describe 'Contact Label API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/<id>/labels' do
    let(:contact) { create(:contact, account: account) }

    before do
      contact.update_labels('label1, label2')
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the labels for the contact' do
        get api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label1')
        expect(response.body).to include('label2')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/<id>/labels' do
    let(:contact) { create(:contact, account: account) }

    before do
      contact.update_labels('label1, label2')
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
             params: { labels: %w[label3 label4] },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:label, account: account, title: 'label3')
        create(:label, account: account, title: 'label4')
      end

      it 'creates labels for the contact' do
        post api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
             params: { labels: %w[label3 label4] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label3')
        expect(response.body).to include('label4')
      end

      it 'drops labels that are not defined on the account' do
        post api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
             params: { labels: %w[label3 unknown] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label3')
        expect(response.body).not_to include('unknown')
        expect(contact.reload.label_list).to contain_exactly('label3')
      end

      it 'matches account labels case-insensitively' do
        create(:label, account: account, title: 'urgent')
        post api_v1_account_contact_labels_url(account_id: account.id, contact_id: contact.id),
             params: { labels: %w[Urgent] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(contact.reload.label_list).to contain_exactly('urgent')
      end
    end
  end
end
