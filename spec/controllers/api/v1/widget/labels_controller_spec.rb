require 'rails_helper'

RSpec.describe '/api/v1/widget/labels', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }

  describe 'POST /api/v1/widget/labels' do
    let(:params) { { website_token: web_widget.website_token, label: 'customer-support' } }

    context 'with correct website token and undefined label' do
      it 'does not add the label' do
        post '/api/v1/widget/labels',
             params: params,
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.label_list.count).to eq 0
      end
    end

    context 'with correct website token and a defined label' do
      before do
        account.labels.create!(title: 'customer-support')
      end

      it 'add the label to the conversation' do
        post '/api/v1/widget/labels',
             params: params,
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.label_list.count).to eq 1
        expect(conversation.reload.label_list.first).to eq 'customer-support'
      end
    end

    context 'with invalid website token' do
      it 'returns the list of labels' do
        post '/api/v1/widget/labels', params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/widget/labels' do
    before do
      conversation.label_list.add('customer-support')
      conversation.save!
    end

    let(:params) { { website_token: web_widget.website_token, label: 'customer-support' } }

    context 'with correct website token' do
      it 'returns the list of labels' do
        delete "/api/v1/widget/labels/#{params[:label]}",
               params: params,
               headers: { 'X-Auth-Token' => token },
               as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.label_list.count).to eq 0
      end
    end

    context 'with invalid website token' do
      it 'returns the list of labels' do
        delete "/api/v1/widget/labels/#{params[:label]}", params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
