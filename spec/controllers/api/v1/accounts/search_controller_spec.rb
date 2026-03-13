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

      it 'returns last_activity_at in contact search results' do
        contact = create(:contact, email: 'activity@test.com', account: account, last_activity_at: 3.days.ago)

        get "/api/v1/accounts/#{account.id}/search/contacts",
            headers: agent.create_new_auth_token,
            params: { q: 'activity' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)

        contact_result = response_data[:payload][:contacts].first
        expect(contact_result[:last_activity_at]).to eq(contact.last_activity_at.to_i)
        expect(contact_result).not_to have_key(:created_at)
      end

      context 'with advanced_search feature enabled', :opensearch do
        before do
          account.enable_features!('advanced_search')
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

      context 'with advanced_search feature enabled', :opensearch do
        before do
          account.enable_features!('advanced_search')
        end

        it 'filters conversations by since parameter' do
          unique_id = SecureRandom.hex(8)
          old_contact = create(:contact, email: "old-#{unique_id}@test.com", account: account)
          recent_contact = create(:contact, email: "recent-#{unique_id}@test.com", account: account)
          old_conversation = create(:conversation, account: account, contact: old_contact)
          recent_conversation = create(:conversation, account: account, contact: recent_contact)
          create(:message, conversation: old_conversation, account: account, content: 'message 1')
          create(:message, conversation: recent_conversation, account: account, content: 'message 2')
          create(:inbox_member, user: agent, inbox: old_conversation.inbox)
          create(:inbox_member, user: agent, inbox: recent_conversation.inbox)

          # Bypass CURRENT_TIMESTAMP default
          # rubocop:disable Rails/SkipsModelValidations
          Conversation.where(id: old_conversation.id).update_all(last_activity_at: 10.days.ago)
          Conversation.where(id: recent_conversation.id).update_all(last_activity_at: 2.days.ago)
          # rubocop:enable Rails/SkipsModelValidations

          get "/api/v1/accounts/#{account.id}/search/conversations",
              headers: agent.create_new_auth_token,
              params: { q: unique_id, since: 5.days.ago.to_i },
              as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)

          conversation_display_ids = response_data[:payload][:conversations].pluck(:id)
          expect(conversation_display_ids).to eq([recent_conversation.display_id])
        end

        it 'filters conversations by until parameter' do
          unique_id = SecureRandom.hex(8)
          old_contact = create(:contact, email: "old-#{unique_id}@test.com", account: account)
          recent_contact = create(:contact, email: "recent-#{unique_id}@test.com", account: account)
          old_conversation = create(:conversation, account: account, contact: old_contact)
          recent_conversation = create(:conversation, account: account, contact: recent_contact)
          create(:message, conversation: old_conversation, account: account, content: 'message 1')
          create(:message, conversation: recent_conversation, account: account, content: 'message 2')
          create(:inbox_member, user: agent, inbox: old_conversation.inbox)
          create(:inbox_member, user: agent, inbox: recent_conversation.inbox)

          # Bypass CURRENT_TIMESTAMP default
          # rubocop:disable Rails/SkipsModelValidations
          Conversation.where(id: old_conversation.id).update_all(last_activity_at: 10.days.ago)
          Conversation.where(id: recent_conversation.id).update_all(last_activity_at: 2.days.ago)
          # rubocop:enable Rails/SkipsModelValidations

          get "/api/v1/accounts/#{account.id}/search/conversations",
              headers: agent.create_new_auth_token,
              params: { q: unique_id, until: 5.days.ago.to_i },
              as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)

          conversation_display_ids = response_data[:payload][:conversations].pluck(:id)
          expect(conversation_display_ids).to eq([old_conversation.display_id])
        end

        it 'filters conversations by both since and until parameters' do
          unique_id = SecureRandom.hex(8)
          very_old_contact = create(:contact, email: "veryold-#{unique_id}@test.com", account: account)
          old_contact = create(:contact, email: "old-#{unique_id}@test.com", account: account)
          recent_contact = create(:contact, email: "recent-#{unique_id}@test.com", account: account)
          very_old_conversation = create(:conversation, account: account, contact: very_old_contact)
          old_conversation = create(:conversation, account: account, contact: old_contact)
          recent_conversation = create(:conversation, account: account, contact: recent_contact)
          create(:message, conversation: very_old_conversation, account: account, content: 'message 1')
          create(:message, conversation: old_conversation, account: account, content: 'message 2')
          create(:message, conversation: recent_conversation, account: account, content: 'message 3')
          create(:inbox_member, user: agent, inbox: very_old_conversation.inbox)
          create(:inbox_member, user: agent, inbox: old_conversation.inbox)
          create(:inbox_member, user: agent, inbox: recent_conversation.inbox)

          # Bypass CURRENT_TIMESTAMP default
          # rubocop:disable Rails/SkipsModelValidations
          Conversation.where(id: very_old_conversation.id).update_all(last_activity_at: 20.days.ago)
          Conversation.where(id: old_conversation.id).update_all(last_activity_at: 10.days.ago)
          Conversation.where(id: recent_conversation.id).update_all(last_activity_at: 2.days.ago)
          # rubocop:enable Rails/SkipsModelValidations

          get "/api/v1/accounts/#{account.id}/search/conversations",
              headers: agent.create_new_auth_token,
              params: { q: unique_id, since: 15.days.ago.to_i, until: 5.days.ago.to_i },
              as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)

          conversation_display_ids = response_data[:payload][:conversations].pluck(:id)
          expect(conversation_display_ids).to eq([old_conversation.display_id])
        end
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

      context 'with advanced_search feature enabled', :opensearch do
        before do
          account.enable_features!('advanced_search')
        end

        it 'filters articles by since parameter' do
          portal = create(:portal, account: account)
          old_article = create(:article, title: 'Old Article test', account: account, portal: portal,
                                         author: agent, status: 'published', updated_at: 10.days.ago)
          recent_article = create(:article, title: 'Recent Article test', account: account, portal: portal,
                                            author: agent, status: 'published', updated_at: 2.days.ago)

          get "/api/v1/accounts/#{account.id}/search/articles",
              headers: agent.create_new_auth_token,
              params: { q: 'test', since: 5.days.ago.to_i },
              as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)

          article_ids = response_data[:payload][:articles].pluck(:id)
          expect(article_ids).to include(recent_article.id)
          expect(article_ids).not_to include(old_article.id)
        end

        it 'filters articles by until parameter' do
          portal = create(:portal, account: account)
          old_article = create(:article, title: 'Old Article test', account: account, portal: portal,
                                         author: agent, status: 'published', updated_at: 10.days.ago)
          recent_article = create(:article, title: 'Recent Article test', account: account, portal: portal,
                                            author: agent, status: 'published', updated_at: 2.days.ago)

          get "/api/v1/accounts/#{account.id}/search/articles",
              headers: agent.create_new_auth_token,
              params: { q: 'test', until: 5.days.ago.to_i },
              as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)

          article_ids = response_data[:payload][:articles].pluck(:id)
          expect(article_ids).to include(old_article.id)
          expect(article_ids).not_to include(recent_article.id)
        end

        it 'filters articles by both since and until parameters' do
          portal = create(:portal, account: account)
          very_old_article = create(:article, title: 'Very Old Article test', account: account, portal: portal,
                                              author: agent, status: 'published', updated_at: 20.days.ago)
          old_article = create(:article, title: 'Old Article test', account: account, portal: portal,
                                         author: agent, status: 'published', updated_at: 10.days.ago)
          recent_article = create(:article, title: 'Recent Article test', account: account, portal: portal,
                                            author: agent, status: 'published', updated_at: 2.days.ago)

          get "/api/v1/accounts/#{account.id}/search/articles",
              headers: agent.create_new_auth_token,
              params: { q: 'test', since: 15.days.ago.to_i, until: 5.days.ago.to_i },
              as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)

          article_ids = response_data[:payload][:articles].pluck(:id)
          expect(article_ids).to include(old_article.id)
          expect(article_ids).not_to include(very_old_article.id, recent_article.id)
        end
      end
    end
  end
end
