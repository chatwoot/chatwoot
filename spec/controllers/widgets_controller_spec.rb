require 'rails_helper'

describe '/widget', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account, website_url: 'https://example.com') }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }

  describe 'GET /widget' do
    it 'renders the page correctly when called with website_token' do
      get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://example.com' }
      expect(response).to be_successful
      expect(response.body).not_to include(token)
    end

    it 'renders the page correctly when called with website_token and cw_conversation' do
      get widget_url(website_token: web_widget.website_token, cw_conversation: token), headers: { 'Origin' => 'https://example.com' }
      expect(response).to be_successful
      expect(response.body).to include(token)
    end

    it 'returns 404 when called with out website_token' do
      get widget_url
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 if the account is suspended' do
      account.update!(status: :suspended)

      get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://example.com' }
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('Account is suspended')
    end

    it 'returns 404 if the webwidget is deleted' do
      web_widget.delete

      get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://example.com' }
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('web widget does not exist')
    end

    describe 'domain validation' do
      context 'when website_url is blank' do
        before { web_widget.update!(website_url: '') }

        it 'allows access without origin validation' do
          get widget_url(website_token: web_widget.website_token)
          expect(response).to be_successful
        end
      end

      context 'when website_url is configured' do
        it 'allows access when origin matches exact domain' do
          get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://example.com' }
          expect(response).to be_successful
        end

        it 'allows access when origin matches domain with same protocol' do
          get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://example.com' }
          expect(response).to be_successful
        end

        it 'denies access when origin matches domain but has different protocol' do
          get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'http://example.com' }
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include('Widget access denied.')
        end

        it 'denies access when origin does not match domain' do
          get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://malicious-site.com' }
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include('Widget access denied.')
        end

        it 'denies access when no origin is provided' do
          get widget_url(website_token: web_widget.website_token)
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include('Widget access denied.')
        end

        # Tests for wildcard domains with protocols (the fix we implemented)
        context 'when website_url contains wildcard domains with protocols' do
          it 'allows access when origin matches wildcard domain with same protocol' do
            web_widget.update!(website_url: 'https://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://client1.testsite.com' }
            expect(response).to be_successful
          end

          it 'allows access when origin matches nested subdomain of wildcard with same protocol' do
            web_widget.update!(website_url: 'https://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://tenant.portal.testsite.com' }
            expect(response).to be_successful
          end

          it 'denies access when origin matches wildcard domain but has different protocol' do
            web_widget.update!(website_url: 'https://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'http://client1.testsite.com' }
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include('Widget access denied.')
          end

          it 'denies access when origin does not match wildcard pattern with protocol' do
            web_widget.update!(website_url: 'https://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://otherportal.com' }
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include('Widget access denied.')
          end

          it 'allows access when origin matches wildcard domain with http protocol' do
            web_widget.update!(website_url: 'http://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'http://client1.testsite.com' }
            expect(response).to be_successful
          end

          it 'denies access when origin matches wildcard domain but has https instead of http' do
            web_widget.update!(website_url: 'http://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://client1.testsite.com' }
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include('Widget access denied.')
          end

          it 'allows access when origin matches any domain in comma-separated list with mixed protocols' do
            web_widget.update!(website_url: 'https://example.com, https://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://client1.testsite.com' }
            expect(response).to be_successful
          end

          it 'allows access when origin matches exact domain in mixed list with protocols' do
            web_widget.update!(website_url: 'https://example.com, https://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://example.com' }
            expect(response).to be_successful
          end

          it 'handles mixed wildcard and exact domains with different protocols' do
            web_widget.update!(website_url: 'https://example.com, http://*.testsite.com')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'http://client1.testsite.com' }
            expect(response).to be_successful
          end

          it 'handles whitespace around comma-separated domains with protocols' do
            web_widget.update!(website_url: '  https://example.com  ,  https://*.testsite.com  ')
            get widget_url(website_token: web_widget.website_token), headers: { 'Origin' => 'https://client1.testsite.com' }
            expect(response).to be_successful
          end
        end
      end
    end
  end
end
