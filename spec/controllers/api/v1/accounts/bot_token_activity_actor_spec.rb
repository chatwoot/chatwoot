require 'rails_helper'

# A request authenticated with an agent bot token NAMES THE BOT on every activity line it writes.
#
# This is a fence, not a new behaviour. `authenticate_access_token!` assigns `Current.user = @resource`
# for an AgentBot (`allowed_current_user_type?` accepts one), and `determine_user_name` reads
# `Current.user&.name` — so the bot's name has always been there. It is fenced because it is easy to
# read the code the other way: `current_user` (the Devise helper) IS nil for a token request, which is
# why `ensure_current_account` has a separate bot branch, and `Current.executed_by` is never assigned.
# fazer-ai/chatwoot#456 was filed on exactly that reading and turned out to be wrong.
#
# What depends on it: the fazer.ai agents runtime writes conversation labels with the INSTANCE ADMIN
# token today, which signs an automated verdict with a person's name (fazer-ai/agents#493). Moving
# that write to the bot's own token is only correct because of what this spec asserts.
RSpec.describe 'activity written by an agent bot token', type: :request do
  let(:account) { create(:account) }
  let(:agent_bot) { create(:agent_bot, name: 'Observadora', account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:headers) { { api_access_token: agent_bot.access_token.token } }

  it 'names the bot on a label line' do
    expect do
      post api_v1_account_conversation_labels_url(account_id: account.id, conversation_id: conversation.display_id),
           params: { labels: %w[cancelamento] }, headers: headers, as: :json
    end.to have_enqueued_job(Conversations::ActivityMessageJob)
      .with(conversation, hash_including(content: 'Observadora added cancelamento'))

    expect(response).to have_http_status(:success)
  end

  it 'names the bot on a status line' do
    expect do
      post toggle_status_api_v1_account_conversation_url(account_id: account.id, id: conversation.display_id),
           params: { status: 'resolved' }, headers: headers, as: :json
    end.to have_enqueued_job(Conversations::ActivityMessageJob)
      .with(conversation, hash_including(content: 'Conversation was marked resolved by Observadora'))
  end

  it 'names the bot on a priority line' do
    expect do
      post toggle_priority_api_v1_account_conversation_url(account_id: account.id, id: conversation.display_id),
           params: { priority: 'high' }, headers: headers, as: :json
    end.to have_enqueued_job(Conversations::ActivityMessageJob)
      .with(conversation, hash_including(content: 'Observadora set the priority to high'))
  end

  # The other half of why the runtime can move the write: reading and replacing a conversation's
  # labels is on the bot allowlist (`BOT_ACCESSIBLE_ENDPOINTS`), and `ConversationPolicy#show?`, which
  # is what the labels controller authorizes against, accepts an agent bot.
  it 'lets the bot read the labels back' do
    conversation.update_labels('cancelamento')

    get api_v1_account_conversation_labels_url(account_id: account.id, conversation_id: conversation.display_id),
        headers: headers, as: :json

    expect(response).to have_http_status(:success)
    expect(response.body).to include('cancelamento')
  end

  it 'refuses a bot that is not authorized on this account' do
    other_bot = create(:agent_bot, name: 'Alheia', account: create(:account))

    post api_v1_account_conversation_labels_url(account_id: account.id, conversation_id: conversation.display_id),
         params: { labels: %w[cancelamento] },
         headers: { api_access_token: other_bot.access_token.token }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
