require 'rails_helper'

RSpec.describe '/api/v1/widget/events', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }

  describe 'POST /api/v1/widget/events' do
    let(:params) { { website_token: web_widget.website_token, name: 'webwidget.triggered', event_info: { test_id: 'test' } } }

    context 'with invalid website token' do
      it 'returns unauthorized' do
        post '/api/v1/widget/events', params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with correct website token' do
      before do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
      end

      it 'dispatches the webwidget event' do
        post '/api/v1/widget/events',
             params: params,
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(params[:name], anything, contact_inbox: contact_inbox,
                                         event_info: { test_id: 'test', browser_language: nil, widget_language: nil, browser: anything })
      end
    end
  end
end
