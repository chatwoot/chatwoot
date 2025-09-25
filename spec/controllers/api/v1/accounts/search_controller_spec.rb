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
