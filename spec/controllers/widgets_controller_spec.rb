require 'rails_helper'

describe '/widget', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id, pubsub_token: contact_inbox.pubsub_token } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }
  let(:rendered_token) { Widget::TokenService.new(token: response.body[/window\.authToken = '([^']+)'/, 1]).decode_token }
  let(:rendered_pubsub_token) { response.body[/window\.chatwootPubsubToken = '([^']+)'/, 1] }

  describe 'GET /widget' do
    it 'renders the page with a token for the created contact when called with website_token' do
      url = widget_url(website_token: web_widget.website_token)

      expect { get url }.to change(Contact, :count).by(1).and change(ContactInbox, :count).by(1)

      expect(response).to be_successful
      created = web_widget.inbox.contact_inboxes.find_by!(source_id: rendered_token[:source_id])
      expect(rendered_token[:inbox_id]).to eq(web_widget.inbox.id)
      expect(rendered_token[:pubsub_token]).to eq(created.pubsub_token)
      expect(rendered_pubsub_token).to eq(created.pubsub_token)
    end

    it 'keeps the session when called with website_token and cw_conversation' do
      url = widget_url(website_token: web_widget.website_token, cw_conversation: token)

      expect { get url }.not_to(change { [Contact.count, ContactInbox.count] })

      expect(response).to be_successful
      expect(response.body).to include(token)
      expect(rendered_pubsub_token).to eq(contact_inbox.pubsub_token)
    end

    it 'creates the contact with the ids of a token issued without one' do
      visitor_payload = { source_id: 'visitor', inbox_id: web_widget.inbox.id, pubsub_token: 'stream' }
      visitor_token = Widget::TokenService.new(payload: visitor_payload).generate_token
      url = widget_url(website_token: web_widget.website_token, cw_conversation: visitor_token)

      expect { get url }.to change(Contact, :count).by(1).and change(ContactInbox, :count).by(1)

      expect(web_widget.inbox.contact_inboxes.find_by!(source_id: 'visitor').pubsub_token).to eq('stream')
      expect(response.body).to include(visitor_token)
      expect(rendered_pubsub_token).to eq('stream')
    end

    it 'reissues a token minted before pubsub_token was part of it' do
      legacy_token = Widget::TokenService.new(payload: payload.except(:pubsub_token)).generate_token

      expect { get widget_url(website_token: web_widget.website_token, cw_conversation: legacy_token) }
        .not_to(change { [Contact.count, ContactInbox.count] })

      expect(response.body).not_to include(legacy_token)
      expect(rendered_token).to include(source_id: contact_inbox.source_id, pubsub_token: contact_inbox.pubsub_token)
      expect(rendered_pubsub_token).to eq(contact_inbox.pubsub_token)
    end

    it 'recreates the contact for a token minted before pubsub_token was part of it when its contact is gone' do
      legacy_token = Widget::TokenService.new(payload: { source_id: 'purged', inbox_id: web_widget.inbox.id }).generate_token

      expect { get widget_url(website_token: web_widget.website_token, cw_conversation: legacy_token) }
        .to change(Contact, :count).by(1)

      expect(response.body).not_to include(legacy_token)
      created = web_widget.inbox.contact_inboxes.find_by!(source_id: 'purged')
      expect(rendered_token).to include(source_id: 'purged', pubsub_token: created.pubsub_token)
    end

    it 'starts a new session when the contact behind the token has been deleted' do
      token
      contact.delete

      expect { get widget_url(website_token: web_widget.website_token, cw_conversation: token) }.to change(Contact, :count).by(1)

      expect(response).to be_successful
      expect(response.body).not_to include(token)
      expect(rendered_token[:source_id]).not_to eq(contact_inbox.source_id)
      expect(rendered_pubsub_token).not_to eq(contact_inbox.pubsub_token)
    end

    it 'starts a new session for a token minted for another inbox' do
      other_widget = create(:channel_widget, account: account)
      token

      expect { get widget_url(website_token: other_widget.website_token, cw_conversation: token) }.to change(Contact, :count).by(1)

      expect(response.body).not_to include(token)
      expect(rendered_token[:inbox_id]).to eq(other_widget.inbox.id)
      expect(rendered_token[:source_id]).not_to eq(contact_inbox.source_id)
      expect(rendered_pubsub_token).not_to eq(contact_inbox.pubsub_token)
    end

    it 'creates a contact for a regular browser' do
      url = widget_url(website_token: web_widget.website_token)
      user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

      expect { get url, headers: { 'User-Agent' => user_agent } }.to change(Contact, :count).by(1).and change(ContactInbox, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('window.authToken')
    end

    context 'when requested by a crawler' do
      %w[Googlebot bingbot].each do |crawler|
        it "returns no content without creating contacts for #{crawler}" do
          url = widget_url(website_token: web_widget.website_token)

          expect { get url, headers: { 'User-Agent' => crawler } }.not_to(change { [Contact.count, ContactInbox.count] })

          expect(response).to have_http_status(:no_content)
          expect(response.headers['X-Robots-Tag']).to eq('noindex')
          expect(response.body).to be_empty
        end
      end

      it 'stops before decoding a supplied visitor token' do
        url = widget_url(website_token: web_widget.website_token, cw_conversation: 'invalid')

        expect { get url, headers: { 'User-Agent' => 'Googlebot' } }.not_to(change { [Contact.count, ContactInbox.count] })

        expect(response).to have_http_status(:no_content)
      end

      it 'still rejects an invalid website token' do
        get widget_url(website_token: 'invalid'), headers: { 'User-Agent' => 'Googlebot' }

        expect(response).to have_http_status(:not_found)
      end

      it 'still rejects suspended accounts' do
        url = widget_url(website_token: web_widget.website_token)
        account.update!(status: :suspended)

        expect { get url, headers: { 'User-Agent' => 'Googlebot' } }.not_to(change { [Contact.count, ContactInbox.count] })

        expect(response).to have_http_status(:unauthorized)
      end
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
