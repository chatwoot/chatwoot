require 'rails_helper'

# Every conversation list loads its message data through Conversations::MessageSummaryLoader,
# so the number of statements that read messages must not grow with the number of conversations.
RSpec.describe 'Conversation list message queries', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:company) { create(:company, account: account) }
  let(:contact) { create(:contact, account: account, company: company) }
  let(:status_filter) { { payload: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'] }] } }

  before { account.enable_features!(:companies) }

  def create_conversation
    conversation = create(:conversation, account: account, inbox: inbox, contact: contact, agent_last_seen_at: 1.hour.ago)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, sender: contact)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, sender: admin)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :activity, sender: nil)
    conversation
  end

  def message_queries(&)
    statements = []
    callback = ->(_name, _start, _finish, _id, payload) { statements << payload[:sql] if payload[:sql].include?('FROM "messages"') }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
    expect(response).to have_http_status(:success)
    statements.size
  end

  shared_examples 'a list that loads message data once' do |payload_path|
    it 'reads messages with the same number of statements for 2 and for 5 conversations' do
      2.times { create_conversation }
      for_two = message_queries { request_list }
      expect(response.parsed_body.dig(*payload_path).size).to eq(2)

      3.times { create_conversation }
      for_five = message_queries { request_list }
      expect(response.parsed_body.dig(*payload_path).size).to eq(5)

      expect(for_five).to eq(for_two)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations' do
    def request_list
      get "/api/v1/accounts/#{account.id}/conversations", headers: admin.create_new_auth_token, as: :json
    end

    it_behaves_like 'a list that loads message data once', %w[data payload]
  end

  it 'renders each conversation as the conversation renders alone' do
    conversations = Array.new(2) { create_conversation }
    conversations.last.update!(agent_last_seen_at: nil)

    get "/api/v1/accounts/#{account.id}/conversations", headers: admin.create_new_auth_token, as: :json
    list = response.parsed_body.dig('data', 'payload').index_by { |conversation| conversation['id'] }

    conversations.each do |conversation|
      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: admin.create_new_auth_token, as: :json

      expect(list[conversation.display_id]).to eq(response.parsed_body)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/filter' do
    def request_list
      post "/api/v1/accounts/#{account.id}/conversations/filter", headers: admin.create_new_auth_token, params: status_filter, as: :json
    end

    it_behaves_like 'a list that loads message data once', %w[payload]
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/{contact.id}/conversations' do
    def request_list
      get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/conversations", headers: admin.create_new_auth_token, as: :json
    end

    it_behaves_like 'a list that loads message data once', %w[payload]
  end

  describe 'GET /api/v1/accounts/{account.id}/companies/{company.id}/conversations' do
    def request_list
      get "/api/v1/accounts/#{account.id}/companies/#{company.id}/conversations", headers: admin.create_new_auth_token, as: :json
    end

    it_behaves_like 'a list that loads message data once', %w[payload]
  end

  describe 'POST /api/v1/accounts/{account.id}/companies/{company.id}/conversations/filter' do
    def request_list
      post "/api/v1/accounts/#{account.id}/companies/#{company.id}/conversations/filter",
           headers: admin.create_new_auth_token, params: status_filter, as: :json
    end

    it_behaves_like 'a list that loads message data once', %w[payload]
  end
end
