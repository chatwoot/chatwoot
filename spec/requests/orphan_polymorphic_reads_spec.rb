require 'rails_helper'

# An install that used Captain and then runs without enterprise/ keeps rows whose polymorphic
# type names a class it no longer has: messages an assistant sent, conversations assigned to
# one. They are not migrated or deleted, since they are right again the day Enterprise is back,
# so reading them has to work without the class.
RSpec.describe 'Rows naming a class this install does not have', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:missing_class) { 'Captain::RetiredAssistant' }
  let(:headers) { agent.create_new_auth_token }

  before { allow(ApplicationRecord).to receive(:missing_polymorphic_classes_tolerated?).and_return(true) }

  it 'loads the conversation history, showing the message without a sender' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, content: 'from the assistant')
    message.update_columns(sender_type: missing_class, sender_id: 42) # rubocop:disable Rails/SkipsModelValidations

    get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages", headers: headers, as: :json

    expect(response).to have_http_status(:success)
    shown = response.parsed_body['payload'].find { |payload| payload['id'] == message.id }
    expect(shown['content']).to eq('from the assistant')
    expect(shown['sender']).to be_nil
  end

  it 'opens a conversation assigned to it, and lists it, without an assignee' do
    conversation.update_columns(ai_assignee_type: missing_class, assignee_agent_bot_id: 42, assignee_id: nil) # rubocop:disable Rails/SkipsModelValidations

    get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: headers, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body['meta']['assignee']).to be_nil

    get "/api/v1/accounts/#{account.id}/conversations", params: { status: 'all', assignee_type: 'all' }, headers: headers, as: :json
    expect(response).to have_http_status(:success)
    listed = response.parsed_body['data']['payload'].find { |payload| payload['id'] == conversation.display_id }
    expect(listed['meta']['assignee']).to be_nil
    # The cable payload says the same, so a live update does not announce an assignee either.
    expect(conversation.reload.push_event_data[:meta]).to include(assignee: nil, assignee_type: nil)
  end

  # The tolerance is for a class that went away with enterprise/, not for a type nobody can
  # explain: with enterprise/ loaded, a name that does not resolve is still a loud error.
  it 'still fails loudly on an unknown class when enterprise/ is loaded' do
    allow(ApplicationRecord).to receive(:missing_polymorphic_classes_tolerated?).and_return(false)
    message = create(:message, account: account, inbox: inbox, conversation: conversation)
    message.update_columns(sender_type: missing_class, sender_id: 42) # rubocop:disable Rails/SkipsModelValidations

    expect { Message.find(message.id).sender }.to raise_error(NameError)
  end
end
