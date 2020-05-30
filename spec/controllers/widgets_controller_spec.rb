require 'rails_helper'

describe '/widget', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }
  let(:participants) { contact_inbox.conversations.last.participants.count }

  describe 'GET /widget' do
    before do
      contact_inbox.create_conversation
    end

    it 'renders the page correctly when called with website_token' do
      old_participants = participants
      get widget_url(website_token: web_widget.website_token)
      expect(response).to be_successful
      expect(response.body).not_to include(token)

      new_participants = contact_inbox.conversations.last.participants.count
      expect(new_participants).to eq(old_participants)
    end

    it 'renders the page correctly when called with website_token and cw_conversation' do
      old_participants = participants
      get widget_url(website_token: web_widget.website_token, cw_conversation: token)
      expect(response).to be_successful
      expect(response.body).to include(token)

      new_participants = contact_inbox.conversations.last.participants.count
      expect(new_participants).to eq(old_participants)
    end

    it 'renders the page correctly when called with  website_token, chatwoot_share_link, and without an existing convesation' do
      contact_inbox.conversations.delete_all
      get widget_url(website_token: web_widget.website_token,
                     chatwoot_share_link: token)
      expect(response).to be_successful
      expect(response.body).to include(token)
    end

    it 'renders the page correctly when called with website_token, chatwoot_share_link, and with an existing convesation' do
      old_participants = participants
      get widget_url(website_token: web_widget.website_token,
                     chatwoot_share_link: token)
      expect(response).to be_successful
      expect(response.body).to include(token)
      expect(response.body).to include(token)
      new_participants = contact_inbox.conversations.last.participants.count
      expect(new_participants).to eq(old_participants + 1)
    end

    it 'renders the page correctly when called with website_token, cw_group_conversation, and chatwoot_share_link' do
      conversation_participant = create(
        :conversation_participant,
        conversation: contact_inbox.conversations.last,
        contact: create(:contact, account: account),
        primary: false
      )

      new_payload = payload.clone
      new_payload[:participant_uuid] = conversation_participant.uuid
      participant_token = ::Widget::TokenService.new(payload: new_payload).generate_token

      get widget_url(website_token: web_widget.website_token,
                     cw_group_conversation: participant_token,
                     chatwoot_share_link: token)
      expect(response).to be_successful
      expect(response.body).to include(token)
      expect(response.body).to include(participant_token)
    end

    it 'returns 404 when called with out website_token' do
      get widget_url
      expect(response.status).to eq(404)
    end
  end
end
