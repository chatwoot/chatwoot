require 'rails_helper'

RSpec.describe 'Monitor automation rules', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:rules_url) { "/api/v1/accounts/#{account.id}/automation_rules" }
  let(:monitors_url) { "/api/v1/accounts/#{account.id}/monitors" }
  let(:rule_params) do
    { name: 'Route refunds', description: 'Assign matched conversations', event_name: 'monitor_matched', monitor_id: monitor.id,
      conditions: [], actions: [{ action_name: 'resolve_conversation', action_params: [] }] }
  end

  before { account.enable_features!('automations', 'reports', 'conversation_monitors') }

  it 'creates a monitor event and returns its linked source' do
    post rules_url, headers: headers, params: rule_params, as: :json

    expect(response).to have_http_status(:success)
    rule = account.automation_rules.sole
    expect(rule).to have_attributes(monitor_id: monitor.id, active: true)

    get rules_url, headers: headers, params: { monitor_id: monitor.id }
    payload = response.parsed_body.fetch('payload').sole
    expect(payload).to include('id' => rule.id, 'monitor_name' => monitor.name, 'monitor_availability' => 'available')
  end

  it 'only lists live monitors as selection candidates' do
    paused = create(:conversation_monitor, account: account, paused_at: Time.current)
    monitor
    get monitors_url, headers: headers, params: { active: 'true' }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('payload').pluck('id')).to contain_exactly(monitor.id)
    expect(response.parsed_body.dig('meta', 'total_count')).to eq(1)
    expect(paused).to be_present
  end

  it 'rejects paused and cross-account monitors at creation' do
    other_monitor = create(:conversation_monitor)
    post rules_url, headers: headers, params: rule_params.merge(monitor_id: other_monitor.id), as: :json
    expect(response).to have_http_status(:unprocessable_entity)

    monitor.update!(paused_at: Time.current)
    post rules_url, headers: headers, params: rule_params, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    post rules_url, headers: headers, params: rule_params.merge(active: false), as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.automation_rules).not_to exist
  end

  it 'rejects direct creation when reports or automations are disabled' do
    monitor
    account.disable_features!('reports')
    post rules_url, headers: headers, params: rule_params, as: :json
    expect(response).to have_http_status(:unprocessable_entity)

    account.enable_features!('reports')
    account.disable_features!('automations')
    post rules_url, headers: headers, params: rule_params, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.automation_rules).not_to exist
  end

  it 'disables linked rules on pause and keeps them disabled after resume' do
    post rules_url, headers: headers, params: rule_params, as: :json
    rule = account.automation_rules.sole

    patch "#{monitors_url}/#{monitor.id}", headers: headers, params: { paused: true }, as: :json
    expect(response).to have_http_status(:ok)
    expect(rule.reload.active).to be(false)

    post "#{monitors_url}/#{monitor.id}/resume", headers: headers,
                                                 params: { mode: 'from_now', collection_version: monitor.reload.collection_version }, as: :json
    expect(response).to have_http_status(:ok)
    expect(rule.reload.active).to be(false)

    patch "#{rules_url}/#{rule.id}", headers: headers, params: { active: true }, as: :json
    expect(response).to have_http_status(:ok)
    expect(rule.reload.active).to be(true)
  end

  it 'disables linked rules on deletion and rejects reactivation' do
    post rules_url, headers: headers, params: rule_params, as: :json
    rule = account.automation_rules.sole

    delete "#{monitors_url}/#{monitor.id}", headers: headers
    expect(response).to have_http_status(:no_content)
    expect(rule.reload.active).to be(false)
    expect(rule.monitor_availability).to eq('deleted')

    patch "#{rules_url}/#{rule.id}", headers: headers, params: { active: true }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)

    post "#{rules_url}/#{rule.id}/clone", headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'lets an inactive orphaned rule be edited after the deleted monitor is removed' do
    post rules_url, headers: headers, params: rule_params, as: :json
    rule = account.automation_rules.sole

    delete "#{monitors_url}/#{monitor.id}", headers: headers
    monitor.destroy!
    expect(rule.reload.monitor_id).to be_nil

    patch "#{rules_url}/#{rule.id}", headers: headers, params: { name: 'Archived refund routing' }, as: :json
    expect(response).to have_http_status(:ok)
    expect(rule.reload).to have_attributes(name: 'Archived refund routing', active: false)

    get rules_url, headers: headers
    expect(response.parsed_body.fetch('payload').sole).to include('monitor_name' => nil, 'monitor_availability' => 'deleted')
  end
end
