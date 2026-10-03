require 'rails_helper'

RSpec.describe 'Token Validation API', type: :request do
  describe 'GET /validate_token' do
    let(:account) { create(:account) }

    context 'when it is an invalid token' do
      it 'returns unauthorized' do
        get '/auth/validate_token'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a valid token' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the labels for the conversation' do
        get '/auth/validate_token',
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.body).to include('payload')
      end
    end

    context 'when the user belongs to many accounts' do
      def count_sql_queries
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _started, _finished, _id, payload|
          next if payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])

          queries << payload[:sql]
        end
        yield
        queries.length
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      def user_with_accounts(count)
        user = create(:user)
        count.times { create(:account_user, user: user, account: create(:account)) }
        user
      end

      it 'does not run additional queries per account membership' do
        few_headers = user_with_accounts(2).create_new_auth_token
        many_headers = user_with_accounts(15).create_new_auth_token

        # warmup so one-time app initialization queries don't skew the first measured request
        get '/auth/validate_token', headers: few_headers

        few_queries = count_sql_queries { get '/auth/validate_token', headers: few_headers }
        expect(response).to have_http_status(:success)

        many_queries = count_sql_queries { get '/auth/validate_token', headers: many_headers }
        expect(response).to have_http_status(:success)

        expect(many_queries).to eq(few_queries)
      end
    end
  end
end
