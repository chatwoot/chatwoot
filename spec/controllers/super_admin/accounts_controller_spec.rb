require 'rails_helper'

RSpec.describe 'Super Admin accounts API', type: :request do
  include ActiveJob::TestHelper

  let!(:super_admin) { create(:super_admin) }
  let!(:account) { create(:account) }

  describe 'GET /super_admin/accounts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/super_admin/accounts'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the list of accounts' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/accounts'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New account')
        expect(response.body).to include(account.name)
      end
    end
  end

  describe 'GET /super_admin/accounts/{account_id}' do
    context 'when it is an authenticated user' do
    end
  end

  describe 'GET /super_admin/accounts/{account_id}/edit' do
    context 'when it is an authenticated user' do
    end
  end

  describe 'PATCH /super_admin/accounts/{account_id}' do
    context 'when it is an authenticated user' do
      it 'updates Captain model overrides without changing unrelated settings' do
        account.update!(
          captain_models: { 'editor' => 'gpt-4.1' },
          keep_pending_on_bot_failure: true
        )
        sign_in(super_admin, scope: :super_admin)

        patch "/super_admin/accounts/#{account.id}",
              params: {
                account: {
                  name: account.name,
                  locale: account.locale,
                  status: account.status,
                  captain_models: {
                    editor: '',
                    assistant: 'gpt-5.2'
                  }
                }
              }

        expect(response).to have_http_status(:redirect)
        expect(account.reload.captain_models).to eq('assistant' => 'gpt-5.2')
        expect(account.keep_pending_on_bot_failure).to be true
      end

      it 'rejects invalid Captain model overrides' do
        sign_in(super_admin, scope: :super_admin)
        existing_captain_models = account.captain_models

        patch "/super_admin/accounts/#{account.id}",
              params: {
                account: {
                  name: account.name,
                  locale: account.locale,
                  status: account.status,
                  captain_models: {
                    label_suggestion: 'gpt-5.1'
                  }
                }
              }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('not a valid model for label_suggestion')
        expect(account.reload.captain_models).to eq(existing_captain_models)
      end
    end
  end

  describe 'POST /super_admin/accounts/{account_id}/reset_cache' do
    before do
      create(:label, account: account)
      create(:inbox, account: account)
      create(:team, account: account)
    end

    after do
      Conversations::UnreadCounts::Store.clear_account!(account.id)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/super_admin/accounts/#{account.id}/reset_cache"
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the list of accounts' do
        expect(account.cache_keys.keys).to contain_exactly(:inbox, :label, :team, :canned_response)
        sign_in(super_admin, scope: :super_admin)

        now_timestamp = Time.now.utc.to_i
        post "/super_admin/accounts/#{account.id}/reset_cache"
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to eq('Cache keys cleared')

        range = now_timestamp..(now_timestamp + 10)
        expect(account.reload.cache_keys.values.all? { |v| range.cover?(v.to_i) }).to be(true)
      end

      it 'clears conversation unread count cache' do
        inbox = account.inboxes.first
        store = Conversations::UnreadCounts::Store
        inbox_key = store.inbox_key(account.id, inbox.id)
        store.mark_base_ready!(account.id)
        store.add_base_membership(account_id: account.id, inbox_id: inbox.id, label_ids: [], conversation_id: 1)

        sign_in(super_admin, scope: :super_admin)
        post "/super_admin/accounts/#{account.id}/reset_cache"

        expect(response).to have_http_status(:redirect)
        expect(store.base_ready?(account.id)).to be(false)
        expect(store.counts_for_keys([inbox_key])).to eq(inbox_key => 0)
      end
    end
  end

  describe 'DELETE /super_admin/accounts/{account_id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/super_admin/accounts/#{account.id}"
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated user' do
      it 'Deletes the account' do
        total_accounts = Account.count
        sign_in(super_admin, scope: :super_admin)

        perform_enqueued_jobs(only: DeleteObjectJob) do
          delete "/super_admin/accounts/#{account.id}"
        end

        expect(Account.count).to eq(total_accounts - 1)
      end
    end
  end
end
