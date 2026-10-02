require 'rails_helper'

RSpec.describe '/api/v1/widget/events', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }

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

      it 'gives a visitor without a contact one when they open the widget' do
        visitor_payload = { source_id: 'visitor', inbox_id: web_widget.inbox.id, pubsub_token: 'stream' }
        visitor_token = Widget::TokenService.new(payload: visitor_payload).generate_token

        expect do
          post '/api/v1/widget/events',
               params: params,
               headers: { 'X-Auth-Token' => visitor_token },
               as: :json
        end.to change(Contact, :count).by(1).and change(ContactInbox, :count).by(1)

        expect(response).to have_http_status(:success)
        visitor_contact_inbox = web_widget.inbox.contact_inboxes.find_by!(source_id: 'visitor')
        expect(visitor_contact_inbox.pubsub_token).to eq('stream')
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(params[:name], anything, hash_including(contact_inbox: visitor_contact_inbox))
      end

      it 'does not create a contact for a token minted before pubsub_token was part of it' do
        legacy_token = Widget::TokenService.new(payload: { source_id: 'purged', inbox_id: web_widget.inbox.id }).generate_token

        expect do
          post '/api/v1/widget/events',
               params: params,
               headers: { 'X-Auth-Token' => legacy_token },
               as: :json
        end.not_to(change { [Contact.count, ContactInbox.count] })

        expect(response).to have_http_status(:not_found)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(params[:name], anything, anything)
      end

      it 'does not create a contact for a token minted for another inbox' do
        other_widget = create(:channel_widget, account: account)
        token

        expect do
          post '/api/v1/widget/events',
               params: params.merge(website_token: other_widget.website_token),
               headers: { 'X-Auth-Token' => token },
               as: :json
        end.not_to(change { [Contact.count, ContactInbox.count] })

        expect(response).to have_http_status(:not_found)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(params[:name], anything, anything)
      end
    end
  end
end
