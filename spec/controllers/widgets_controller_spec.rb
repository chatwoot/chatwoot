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

  describe 'cross-origin embed headers' do
    # allowed_domains is stored host-only (the documented/UI format), while the
    # browser sends Origin with a scheme.
    let(:allowed_domain) { 'embed.example.com' }
    let(:origin) { 'https://embed.example.com' }

    def get_widget(origin:, **)
      get(widget_url(website_token: web_widget.website_token),
          headers: { 'Origin' => origin }, **)
    end

    context 'when allow_cross_origin_isolation is disabled (default)' do
      before { web_widget.update!(allowed_domains: allowed_domain) }

      it 'does not emit cross-origin isolation or CORS headers' do
        get_widget(origin: origin)

        expect(response.headers).not_to include('Cross-Origin-Embedder-Policy')
        expect(response.headers).not_to include('Cross-Origin-Resource-Policy')
        expect(response.headers).not_to include('Access-Control-Allow-Origin')
      end
    end

    context 'when allow_cross_origin_isolation is enabled' do
      before do
        web_widget.update!(allowed_domains: allowed_domain,
                           selected_feature_flags: %w[allow_cross_origin_isolation])
      end

      it 'emits COEP and CORP so the widget can load in a cross-origin-isolated parent' do
        get_widget(origin: origin)

        expect(response.headers['Cross-Origin-Embedder-Policy']).to eq('credentialless')
        expect(response.headers['Cross-Origin-Resource-Policy']).to eq('cross-origin')
      end

      # Origin-matching detail is covered by Widget::EmbedPolicy specs; here we
      # only assert the controller wires the policy into the CORS header.
      it 'echoes Access-Control-Allow-Origin for an allowed origin' do
        get_widget(origin: origin)

        expect(response.headers['Access-Control-Allow-Origin']).to eq(origin)
        expect(response.headers['Vary'].to_s).to include('Origin')
      end

      it 'does not echo Access-Control-Allow-Origin for a disallowed origin' do
        get_widget(origin: 'https://evil.example.com')

        expect(response.headers).not_to include('Access-Control-Allow-Origin')
      end
    end
  end
end
