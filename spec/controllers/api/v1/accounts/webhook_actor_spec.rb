require 'rails_helper'

RSpec.describe 'Conversation webhook actor authentication', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

  after { Current.reset }

  %i[user agent_bot].each do |actor_type|
    it "captures the #{actor_type} token owner in the queued event" do
      actor = create(actor_type, account: account)
      if actor_type == :user
        create(:inbox_member, inbox: inbox, user: actor)
      else
        create(:agent_bot_inbox, inbox: inbox, agent_bot: actor)
      end
      conversation
      allow(EventDispatcherJob).to receive(:perform_later)

      post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
           headers: { api_access_token: actor.access_token.token }, params: { status: 'resolved' }, as: :json

      expect(response).to have_http_status(:success)
      expect(EventDispatcherJob).to have_received(:perform_later).with(
        'conversation.status_changed', anything,
        hash_including(webhook_actor: { type: actor_type.to_s, id: actor.id })
      )
    end
  end
end
