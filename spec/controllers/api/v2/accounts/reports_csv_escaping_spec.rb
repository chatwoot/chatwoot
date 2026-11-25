require 'rails_helper'

# Every CSV export is an ERB template, and ActionView escapes `<%= %>` output for any
# template type outside its ignore list. `text/csv` is not in it, so an apostrophe in a
# name used to reach the file as `&#39;`.
RSpec.describe 'Reports CSV escaping', type: :request do
  let(:hostile_name) { %(O'Keefe & <Sons>) }
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, name: hostile_name) }
  let!(:inbox) { create(:inbox, account: account, name: hostile_name) }
  let!(:team) { create(:team, account: account, name: hostile_name) }
  let(:params) { { timezone_offset: 0, since: 1.day.ago.to_i.to_s, until: Time.current.to_i.to_s } }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create_list(:conversation, 2, account: account, inbox: inbox, assignee: agent, team: team,
                                  created_at: Time.current)
  end

  # Only these three carry free text. A label title is restricted to letters, numbers,
  # hyphen and underscore, and the summary and traffic exports are counts and timestamps.
  %w[agents inboxes teams].each do |report|
    it "leaves the #{report} export unescaped" do
      get "/api/v2/accounts/#{account.id}/reports/#{report}.csv", params: params, headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('&#39;', '&amp;', '&lt;', '&gt;', '&quot;')
    end
  end

  it 'leaves the CSAT export unescaped' do
    conversation = account.conversations.first
    create(:csat_survey_response, account: account, conversation: conversation, assigned_agent: agent,
                                  feedback_message: hostile_name)

    get "/api/v1/accounts/#{account.id}/csat_survey_responses/download.csv", params: params,
                                                                             headers: admin.create_new_auth_token

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('&#39;', '&amp;', '&lt;', '&gt;', '&quot;')
  end

  # The rename that put `conversation_traffic` under `.csv.erb` is what the ignore list
  # keys on, so a template added without the format in its name would silently opt out.
  it 'resolves every report template as text/csv' do
    lookup = ApplicationController.new.lookup_context

    %w[agents inboxes labels teams conversations_summary conversation_traffic].each do |report|
      template = lookup.find_template("api/v2/accounts/reports/#{report}", [], false, [], formats: [:csv])

      expect(template.type.to_s).to eq('text/csv'), "#{report} resolves as #{template.type.inspect}"
    end
  end

  it 'still defuses a formula in a name' do
    agent.update!(name: '=cmd|calc')

    get "/api/v2/accounts/#{account.id}/reports/agents.csv", params: params, headers: admin.create_new_auth_token

    expect(response.body).to include(%('=cmd|calc))
  end
end
