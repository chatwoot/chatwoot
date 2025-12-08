require 'rails_helper'

RSpec.describe 'Search', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    contact = create(:contact, email: 'test@example.com', account: account)
    conversation = create(:conversation, account: account, contact_id: contact.id)
    create(:message, conversation: conversation, account: account, content: 'test1')
    create(:message, conversation: conversation, account: account, content: 'test2')
    create(:contact_inbox, contact_id: contact.id, inbox_id: conversation.inbox.id)
    create(:inbox_member, user: agent, inbox: conversation.inbox)

    # Create articles for testing
    portal = create(:portal, account: account)
    create(:article, title: 'Test Article Guide', content: 'This is a test article content',
                     account: account, portal: portal, author: agent, status: 'published')
  end

  describe 'GET /api/v1/accounts/{account.id}/search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/search", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all conversations with messages containing the search query' do
        get "/api/v1/accounts/#{account.id}/search",
            headers: agent.create_new_auth_token,
            params: { q: 'test' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        expect(response_data[:payload][:messages].first[:content]).to eq 'test2'
        expect(response_data[:payload].keys).to contain_exactly(:contacts, :conversations, :messages, :articles)
        expect(response_data[:payload][:messages].length).to eq 2
        expect(response_data[:payload][:conversations].length).to eq 1
        expect(response_data[:payload][:contacts].length).to eq 1
        expect(response_data[:payload][:articles].length).to eq 1
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/search/contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/search/contacts", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all conversations with messages containing the search query' do
        get "/api/v1/accounts/#{account.id}/search/contacts",
            headers: agent.create_new_auth_token,
            params: { q: 'test' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        expect(response_data[:payload].keys).to contain_exactly(:contacts)
        expect(response_data[:payload][:contacts].length).to eq 1
      end

      it 'filters contacts by since parameter' do
        create(:contact, email: 'old@test.com', account: account, last_activity_at: 10.days.ago)
        create(:contact, email: 'recent@test.com', account: account, last_activity_at: 2.days.ago)

        get "/api/v1/accounts/#{account.id}/search/contacts",
            headers: agent.create_new_auth_token,
            params: { q: 'test', since: 5.days.ago.to_i },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        contact_emails = response_data[:payload][:contacts].pluck(:email)
        expect(contact_emails).to include('recent@test.com')
        expect(contact_emails).not_to include('old@test.com')
      end

      it 'filters contacts by until parameter' do
        create(:contact, email: 'old@test.com', account: account, last_activity_at: 10.days.ago)
        create(:contact, email: 'recent@test.com', account: account, last_activity_at: 2.days.ago)

        get "/api/v1/accounts/#{account.id}/search/contacts",
            headers: agent.create_new_auth_token,
            params: { q: 'test', until: 5.days.ago.to_i },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        contact_emails = response_data[:payload][:contacts].pluck(:email)
        expect(contact_emails).to include('old@test.com')
        expect(contact_emails).not_to include('recent@test.com')
      end

      it 'filters contacts by both since and until parameters' do
        create(:contact, email: 'veryold@test.com', account: account, last_activity_at: 20.days.ago)
        create(:contact, email: 'old@test.com', account: account, last_activity_at: 10.days.ago)
        create(:contact, email: 'recent@test.com', account: account, last_activity_at: 2.days.ago)

        get "/api/v1/accounts/#{account.id}/search/contacts",
            headers: agent.create_new_auth_token,
            params: { q: 'test', since: 15.days.ago.to_i, until: 5.days.ago.to_i },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        contact_emails = response_data[:payload][:contacts].pluck(:email)
        expect(contact_emails).to include('old@test.com')
        expect(contact_emails).not_to include('veryold@test.com', 'recent@test.com')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/search/conversations' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/search/conversations", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all conversations with messages containing the search query' do
        get "/api/v1/accounts/#{account.id}/search/conversations",
            headers: agent.create_new_auth_token,
            params: { q: 'test' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        expect(response_data[:payload].keys).to contain_exactly(:conversations)
        expect(response_data[:payload][:conversations].length).to eq 1
      end

      it 'filters conversations by since parameter' do
        old_contact = create(:contact, email: 'oldtimefilter@test.com', account: account)
        recent_contact = create(:contact, email: 'recenttimefilter@test.com', account: account)
        old_conversation = create(:conversation, account: account, contact: old_contact, last_activity_at: 10.days.ago)
        recent_conversation = create(:conversation, account: account, contact: recent_contact, last_activity_at: 2.days.ago)
        create(:message, conversation: old_conversation, account: account, content: 'message 1')
        create(:message, conversation: recent_conversation, account: account, content: 'message 2')
        create(:inbox_member, user: agent, inbox: old_conversation.inbox)
        create(:inbox_member, user: agent, inbox: recent_conversation.inbox)

        get "/api/v1/accounts/#{account.id}/search/conversations",
            headers: agent.create_new_auth_token,
            params: { q: 'timefilter', since: 5.days.ago.to_i },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        conversation_ids = response_data[:payload][:conversations].pluck(:id)
        expect(conversation_ids).to include(recent_conversation.id)
        expect(conversation_ids).not_to include(old_conversation.id)
      end

      it 'filters conversations by until parameter' do
        old_contact = create(:contact, email: 'olduntilfilter@test.com', account: account)
        recent_contact = create(:contact, email: 'recentuntilfilter@test.com', account: account)
        old_conversation = create(:conversation, account: account, contact: old_contact, last_activity_at: 10.days.ago)
        recent_conversation = create(:conversation, account: account, contact: recent_contact, last_activity_at: 2.days.ago)
        create(:message, conversation: old_conversation, account: account, content: 'message 1')
        create(:message, conversation: recent_conversation, account: account, content: 'message 2')
        create(:inbox_member, user: agent, inbox: old_conversation.inbox)
        create(:inbox_member, user: agent, inbox: recent_conversation.inbox)

        get "/api/v1/accounts/#{account.id}/search/conversations",
            headers: agent.create_new_auth_token,
            params: { q: 'untilfilter', until: 5.days.ago.to_i },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        conversation_ids = response_data[:payload][:conversations].pluck(:id)
        expect(conversation_ids).to include(old_conversation.id)
        expect(conversation_ids).not_to include(recent_conversation.id)
      end

      it 'filters conversations by both since and until parameters' do
        very_old_contact = create(:contact, email: 'veryoldrangefilter@test.com', account: account)
        old_contact = create(:contact, email: 'oldrangefilter@test.com', account: account)
        recent_contact = create(:contact, email: 'recentrangefilter@test.com', account: account)
        very_old_conversation = create(:conversation, account: account, contact: very_old_contact, last_activity_at: 20.days.ago)
        old_conversation = create(:conversation, account: account, contact: old_contact, last_activity_at: 10.days.ago)
        recent_conversation = create(:conversation, account: account, contact: recent_contact, last_activity_at: 2.days.ago)
        create(:message, conversation: very_old_conversation, account: account, content: 'message 1')
        create(:message, conversation: old_conversation, account: account, content: 'message 2')
        create(:message, conversation: recent_conversation, account: account, content: 'message 3')
        create(:inbox_member, user: agent, inbox: very_old_conversation.inbox)
        create(:inbox_member, user: agent, inbox: old_conversation.inbox)
        create(:inbox_member, user: agent, inbox: recent_conversation.inbox)

        get "/api/v1/accounts/#{account.id}/search/conversations",
            headers: agent.create_new_auth_token,
            params: { q: 'rangefilter', since: 15.days.ago.to_i, until: 5.days.ago.to_i },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        conversation_ids = response_data[:payload][:conversations].pluck(:id)
        expect(conversation_ids).to include(old_conversation.id)
        expect(conversation_ids).not_to include(very_old_conversation.id, recent_conversation.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/search/messages' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/search/messages", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all conversations with messages containing the search query' do
        get "/api/v1/accounts/#{account.id}/search/messages",
            headers: agent.create_new_auth_token,
            params: { q: 'test' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        expect(response_data[:payload].keys).to contain_exactly(:messages)
        expect(response_data[:payload][:messages].length).to eq 2
      end

      it 'returns 422 when search service raises ArgumentError' do
        error_message = 'Search is limited to the last 90 days'
        allow_any_instance_of(SearchService).to receive(:perform).and_raise(ArgumentError, error_message) # rubocop:disable RSpec/AnyInstance

        get "/api/v1/accounts/#{account.id}/search/messages",
            headers: agent.create_new_auth_token,
            params: { q: 'test' },
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:error]).to eq(error_message)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/search/articles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/search/articles", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all articles containing the search query' do
        get "/api/v1/accounts/#{account.id}/search/articles",
            headers: agent.create_new_auth_token,
            params: { q: 'test' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        expect(response_data[:payload].keys).to contain_exactly(:articles)
        expect(response_data[:payload][:articles].length).to eq 1
        expect(response_data[:payload][:articles].first[:title]).to eq 'Test Article Guide'
      end

      it 'returns empty results when no articles match the search query' do
        get "/api/v1/accounts/#{account.id}/search/articles",
            headers: agent.create_new_auth_token,
            params: { q: 'nonexistent' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        expect(response_data[:payload].keys).to contain_exactly(:articles)
        expect(response_data[:payload][:articles].length).to eq 0
      end

      it 'supports pagination' do
        portal = create(:portal, account: account)
        16.times do |i|
          create(:article, title: "Test Article #{i}", account: account, portal: portal, author: agent, status: 'published')
        end

        get "/api/v1/accounts/#{account.id}/search/articles",
            headers: agent.create_new_auth_token,
            params: { q: 'test', page: 1 },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        expect(response_data[:payload][:articles].length).to eq 15 # Default per_page is 15
      end
    end
  end
end
