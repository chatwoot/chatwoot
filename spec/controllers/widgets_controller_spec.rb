require 'rails_helper'

describe '/widget', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }

  describe 'GET /widget' do
    it 'renders the page correctly when called with website_token' do
      get widget_url(website_token: web_widget.website_token)
      expect(response).to be_successful
      expect(response.body).not_to include(token)
    end

    it 'renders the page correctly when called with website_token and cw_conversation' do
      get widget_url(website_token: web_widget.website_token, cw_conversation: token)
      expect(response).to be_successful
      expect(response.body).to include(token)
    end

    it 'restores the session from the cw_conversation cookie' do
      get widget_url(website_token: web_widget.website_token), headers: { 'Cookie' => "cw_conversation=#{token}" }
      expect(response).to be_successful
      expect(response.body).to include(token)
    end

    it 'prefers a legacy cw_conversation query token over a cookie from another inbox' do
      other_contact = create(:contact, account: account)
      other_inbox = create(:contact_inbox, contact: other_contact, inbox: web_widget.inbox)
      other_token = Widget::TokenService.new(
        payload: { source_id: other_inbox.source_id, inbox_id: web_widget.inbox.id }
      ).generate_token

      get widget_url(website_token: web_widget.website_token, cw_conversation: token),
          headers: { 'Cookie' => "cw_conversation=#{other_token}" }

      expect(response).to be_successful
      expect(response.body).to include(token)
      expect(response.body).not_to include(other_token)
      expect(response.cookies['cw_conversation']).to eq(token)
    end

    it 'restores the session from X-Auth-Token' do
      get widget_url(website_token: web_widget.website_token), headers: { 'X-Auth-Token' => token }
      expect(response).to be_successful
      expect(response.body).to include(token)
    end

    it 'restores the session from an Authorization Bearer token' do
      get widget_url(website_token: web_widget.website_token), headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to be_successful
      expect(response.body).to include(token)
    end

    it 'sets an HttpOnly cw_conversation cookie' do
      get widget_url(website_token: web_widget.website_token)
      expect(response).to be_successful
      expect(response.cookies['cw_conversation']).to be_present
      expect(response.headers['Set-Cookie']).to match(/cw_conversation=.+;.+HttpOnly/i)
    end

    it 'returns 404 when called with out website_token' do
      get widget_url
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 if the account is suspended' do
      account.update!(status: :suspended)

      get widget_url(website_token: web_widget.website_token)
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('Account is suspended')
    end

    it 'returns 404 if the webwidget is deleted' do
      web_widget.delete

      get widget_url(website_token: web_widget.website_token)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('web widget does not exist')
    end
  end
end
