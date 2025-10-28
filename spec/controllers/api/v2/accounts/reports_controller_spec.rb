require 'rails_helper'

RSpec.describe Api::V2::Accounts::ReportsController, type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v2/accounts/{account.id}/reports' do
    context 'when authenticated and authorized' do
      before do
        # Create conversations across 24 hours at different times
        base_time = Time.utc(2024, 1, 14, 23, 0) # Start at 23:00 to span 2 days

        # Create conversations every 4 hours across 24 hours
        6.times do |i|
          time = base_time + (i * 4).hours
          travel_to time do
            conversation = create(:conversation, account: account, inbox: inbox, assignee: agent)
            create(:message, account: account, conversation: conversation, message_type: :outgoing)
          end
        end
      end

      it 'timezone_offset affects data grouping and timestamps correctly' do
        travel_to Time.utc(2024, 1, 15, 12, 0) do
          Time.use_zone('UTC') do
            base_time = Time.utc(2024, 1, 14, 23, 0) # Start at 23:00 to span 2 days
            base_params = {
              metric: 'conversations_count',
              type: 'account',
              since: (base_time - 1.day).to_i.to_s,
              until: (base_time + 2.days).to_i.to_s,
              group_by: 'day'
            }

            responses = [0, -8, 9].map do |offset|
              get "/api/v2/accounts/#{account.id}/reports",
                  params: base_params.merge(timezone_offset: offset),
                  headers: admin.create_new_auth_token, as: :json
              response.parsed_body
            end

            data_entries = responses.map { |r| r.select { |e| e['value'] > 0 } }
            totals = responses.map { |r| r.sum { |e| e['value'] } }
            timestamps = responses.map { |r| r.map { |e| e['timestamp'] } }

            # Data conservation and redistribution
            expect(totals.uniq).to eq([6])
            expect(data_entries[0].map { |e| e['value'] }).to eq([1, 5])
            expect(data_entries[1].map { |e| e['value'] }).to eq([3, 3])
            expect(data_entries[2].map { |e| e['value'] }).to eq([4, 2])

            # Timestamp differences
            expect(timestamps.uniq.size).to eq(3)
            timestamps[0].zip(timestamps[1]).each { |utc, pst| expect(utc - pst).to eq(-28_800) }
          end
        end
      end

      describe 'timezone_offset does not affect summary report totals' do
        let(:base_time) { Time.utc(2024, 1, 15, 12, 0) }
        let(:summary_params) do
          {
            type: 'account',
            since: (base_time - 1.day).to_i.to_s,
            until: (base_time + 1.day).to_i.to_s
          }
        end

        let(:jst_params) do
          # For JST: User wants "Jan 15 JST" which translates to:
          # Jan 14 15:00 UTC to Jan 15 15:00 UTC (event NOT included)
          {
            type: 'account',
            since: (Time.utc(2024, 1, 15, 0, 0) - 9.hours).to_i.to_s, # Jan 14 15:00 UTC
            until: (Time.utc(2024, 1, 16, 0, 0) - 9.hours).to_i.to_s  # Jan 15 15:00 UTC
          }
        end
        let(:utc_params) do
          # For UTC: Jan 15 00:00 UTC to Jan 16 00:00 UTC (event included)
          {
            type: 'account',
            since: Time.utc(2024, 1, 15, 0, 0).to_i.to_s,
            until: Time.utc(2024, 1, 16, 0, 0).to_i.to_s
          }
        end

        it 'returns identical conversation counts across timezones' do
          Time.use_zone('UTC') do
            summaries = [-8, 0, 9].map do |offset|
              get "/api/v2/accounts/#{account.id}/reports/summary",
                  params: summary_params.merge(timezone_offset: offset),
                  headers: admin.create_new_auth_token, as: :json
              response.parsed_body
            end

            conversation_counts = summaries.map { |s| s['conversations_count'] }
            expect(conversation_counts.uniq).to eq([6])
          end
        end

        it 'returns identical message counts across timezones' do
          Time.use_zone('UTC') do
            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: summary_params.merge(timezone_offset: 0),
                headers: admin.create_new_auth_token, as: :json
            utc_summary = response.parsed_body

            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: summary_params.merge(timezone_offset: -8),
                headers: admin.create_new_auth_token, as: :json
            pst_summary = response.parsed_body

            expect(utc_summary['incoming_messages_count']).to eq(pst_summary['incoming_messages_count'])
            expect(utc_summary['outgoing_messages_count']).to eq(pst_summary['outgoing_messages_count'])
          end
        end

        it 'returns consistent resolution counts across timezones' do
          Time.use_zone('UTC') do
            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: summary_params.merge(timezone_offset: 0),
                headers: admin.create_new_auth_token, as: :json
            utc_summary = response.parsed_body

            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: summary_params.merge(timezone_offset: 9),
                headers: admin.create_new_auth_token, as: :json
            jst_summary = response.parsed_body

            expect(utc_summary['resolutions_count']).to eq(jst_summary['resolutions_count'])
          end
        end

        it 'returns consistent previous period data across timezones' do
          Time.use_zone('UTC') do
            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: summary_params.merge(timezone_offset: 0),
                headers: admin.create_new_auth_token, as: :json
            utc_summary = response.parsed_body

            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: summary_params.merge(timezone_offset: -8),
                headers: admin.create_new_auth_token, as: :json
            pst_summary = response.parsed_body

            expect(utc_summary['previous']['conversations_count']).to eq(pst_summary['previous']['conversations_count']) if utc_summary['previous']
          end
        end

        it 'summary reports work when frontend sends correct timezone boundaries' do
          Time.use_zone('UTC') do
            # Create a resolution event right at timezone boundary
            boundary_time = Time.utc(2024, 1, 15, 23, 30) # 11:30 PM UTC on Jan 15
            gravatar_url = 'https://www.gravatar.com'
            stub_request(:get, /#{gravatar_url}.*/).to_return(status: 404)

            travel_to boundary_time do
              perform_enqueued_jobs do
                conversation = create(:conversation, account: account, inbox: inbox, assignee: agent)
                conversation.resolved!
              end
            end

            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: jst_params.merge(timezone_offset: 9),
                headers: admin.create_new_auth_token, as: :json
            jst_summary = response.parsed_body

            get "/api/v2/accounts/#{account.id}/reports/summary",
                params: utc_params.merge(timezone_offset: 0),
                headers: admin.create_new_auth_token, as: :json
            utc_summary = response.parsed_body

            expect(jst_summary['resolutions_count']).to eq(0)
            expect(utc_summary['resolutions_count']).to eq(1)
          end
        end
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v2/accounts/#{account.id}/reports"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated but not authorized' do
      it 'returns forbidden' do
        get "/api/v2/accounts/#{account.id}/reports",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
