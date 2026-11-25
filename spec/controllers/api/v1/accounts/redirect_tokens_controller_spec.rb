require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::RedirectTokensController', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:web_widget) { create(:channel_widget, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/redirect_tokens' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'mints a redirect token for a web widget inbox' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1', message: 'Hi' },
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['token']).to be_present
        expect(body['expires_in']).to eq(Widget::RedirectToken::DEFAULT_TTL)
        expect(body['website_url']).to eq(web_widget.website_url)
        expect(Widget::RedirectToken.consume(body['token']))
          .to eq('inbox_id' => web_widget.inbox.id, 'identifier' => 'user-1', 'message' => 'Hi')
      end

      it 'honours a custom ttl_seconds' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1', ttl_seconds: 60 },
             as: :json

        expect(response.parsed_body['expires_in']).to eq(60)
      end

      it 'clamps a ttl_seconds above the default down to the default' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1', ttl_seconds: 10.years.to_i },
             as: :json

        expect(response.parsed_body['expires_in']).to eq(Widget::RedirectToken::DEFAULT_TTL)
      end

      it 'clamps a non-positive ttl_seconds up to a positive value' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1', ttl_seconds: -5 },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['expires_in']).to be >= 1
      end

      it 'omits blank optional attributes from the stored payload' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1' },
             as: :json

        token = response.parsed_body['token']
        expect(Widget::RedirectToken.consume(token)).to eq('inbox_id' => web_widget.inbox.id, 'identifier' => 'user-1')
      end

      it 'rejects a non web widget inbox' do
        email_inbox = create(:channel_email, account: account).inbox

        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: email_inbox.id, identifier: 'user-1' },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('not_a_web_widget')
      end

      # fazer-ai/agents#222: the origin conversation only exists as a fact at mint time.
      it 'carries the origin conversation into the token payload' do
        origin = create(:conversation, account: account)

        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1', origin_display_id: origin.display_id },
             as: :json

        expect(response).to have_http_status(:success)
        payload = Widget::RedirectToken.consume(response.parsed_body['token'])
        expect(payload['origin_display_id']).to eq(origin.display_id)
      end

      # A display_id is account-wide and guessable, and the consumer RESOLVES the conversation the
      # pairing names, so the right to name it is settled at the mint.
      it 'refuses an origin the caller cannot see' do
        other_inbox = create(:inbox, account: account)
        origin = create(:conversation, account: account, inbox: other_inbox)
        create(:inbox_member, user: agent, inbox: web_widget.inbox)

        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: agent.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1', origin_display_id: origin.display_id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'refuses an origin that does not exist' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1', origin_display_id: 999_999 },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'omits the origin when the caller sends none' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1' },
             as: :json

        payload = Widget::RedirectToken.consume(response.parsed_body['token'])
        expect(payload).not_to have_key('origin_display_id')
      end

      it 'returns not found for an inbox from another account' do
        other_widget = create(:channel_widget)

        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: other_widget.inbox.id, identifier: 'user-1' },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns unauthorized for an agent not assigned to the inbox' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: agent.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'user-1' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    # THE CONTACT THE LINK IS FOR (fazer-ai/agents#286).
    #
    # Named by the caller, because only the caller knows: the resolve side had the `identifier` to go
    # on, and that value is derived from a sequential contact id, so it is guessable and it can move.
    # This endpoint is account-authenticated, so what it is told here is a fact the widget side can
    # spend.
    context 'when the caller names the contact the link is for' do
      let(:lead) { create(:contact, account: account, identifier: 'fzwa:99') }

      it 'carries it in the token payload' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'fzwa:99', contact_id: lead.id },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Widget::RedirectToken.consume(response.parsed_body['token'])['identified_contact_id'])
          .to eq(lead.id)
      end

      it 'refuses a contact from another account instead of naming it' do
        theirs = create(:contact, account: create(:account))

        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'fzwa:99', contact_id: theirs.id },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    # The omission is the older, looser contract and it stays: a caller minting a deep link for an
    # identity this account has never seen wants the resolve to create it.
    context 'when the caller names no contact' do
      it 'leaves the key out of the payload' do
        post "/api/v1/accounts/#{account.id}/redirect_tokens",
             headers: admin.create_new_auth_token,
             params: { inbox_id: web_widget.inbox.id, identifier: 'crm-user-42' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Widget::RedirectToken.consume(response.parsed_body['token']))
          .not_to have_key('identified_contact_id')
      end
    end
  end
end
