require 'rails_helper'

RSpec.describe Copilot::V2::Resources do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:service) { described_class.new(account: account, user: user) }
  let(:processor) { instance_double(Integrations::Linear::ProcessorService) }

  def input(field, value)
    { 'field' => field, 'operator' => 'eq', 'value' => value }
  end

  before { allow(Integrations::Linear::ProcessorService).to receive(:new).with(account: account).and_return(processor) }

  {
    'linear_issues' => ['search_issue', %w[query bug]],
    'linear_teams' => ['teams', nil],
    'linear_team_entities' => ['team_entities', %w[team_id 12345678-1234-1234-1234-123456789012]],
    'linear_linked_issues' => ['linked_issues', nil]
  }.each do |resource, (method, argument)|
    it "captures native identities and safe partial coverage for #{resource}, and denies a disabled hook" do # rubocop:disable RSpec/MultipleExpectations
      hook = create(:integrations_hook, :linear, account: account)
      filters = argument ? [input(*argument)] : []
      if resource == 'linear_linked_issues'
        inbox = create(:inbox, account: account)
        create(:inbox_member, inbox: inbox, user: user)
        conversation = create(:conversation, account: account, inbox: inbox)
        filters = [input('conversation_id', conversation.id)]
      end
      payload = if resource == 'linear_team_entities'
                  { users: [{ id: 'u1', name: 'User', access_token: 'secret' }], projects: [], states: [], labels: [] }
                else
                  [{ id: 'remote-1', title: 'Issue', name: 'Team', access_token: 'secret',
                     issue: { id: 'issue-1', description: 'linked context', access_token: 'secret' } }]
                end
      allow(processor).to receive(method).and_return(data: payload)
      expect(service).not_to receive(:snapshot)
      selected = service.select(resource: resource, filters: filters)
      expect(selected['selected_ids']).to all(be_a(String))
      expect(selected.dig('selection', 'complete')).to be false
      expect(selected.dig('selection', 'matching_count')).to be_nil
      expect(selected.to_json).not_to include('secret', 'access_token')
      evidence = service.read_related(selected, relationship: 'content')
      expect(evidence['resolved_ids']).to eq(selected['selected_ids'])
      expect(service.authorize_manifest!(evidence)).to be true
      hook.update!(status: :disabled)
      expect { service.authorize_manifest!(evidence) }.to raise_error(Pundit::NotAuthorizedError)
      expect { service.select(resource: resource, filters: filters) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  it 'validates interpolated Linear identifiers and denies hidden conversation links before an external request' do
    create(:integrations_hook, :linear, account: account)
    expect(processor).not_to receive(:team_entities)
    expect { service.select(resource: 'linear_team_entities', filters: [input('team_id', '") { users')]) }.to raise_error(ArgumentError)
    expect(processor).not_to receive(:linked_issues)
    hidden = create(:conversation, account: account)
    expect do
      service.select(resource: 'linear_linked_issues', filters: [input('conversation_id', hidden.id)])
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'bounds integration execution without changing shared clients' do
    create(:integrations_hook, :linear, account: account)
    expect(Timeout).to receive(:timeout).with(Copilot::V2::Limits::EXTERNAL_TIMEOUT).and_raise(Timeout::Error)
    expect { service.select(resource: 'linear_teams') }.to raise_error(ArgumentError, 'external_read_timeout:linear_teams')
  end

  context 'with Shopify' do
    let(:client) { instance_double(ShopifyAPI::Clients::Rest::Admin) }
    let(:contact) { create(:contact, account: account, email: 'owner@example.com') }
    let!(:hook) { create(:integrations_hook, :shopify, account: account) }

    before { allow(ShopifyAPI::Clients::Rest::Admin).to receive(:new).and_return(client) }

    it 'uses only existing customer/order GET reads and preserves partial pagination and native identity' do
      allow(client).to receive(:get).with(path: 'customers/search.json', query: anything)
                                    .and_return(instance_double(ShopifyAPI::Clients::HttpResponse,
                                                                body: { 'customers' => [{ 'id' => 10, 'email' => contact.email }] }))
      allow(client).to receive(:get).with(path: 'orders.json', query: hash_including(customer_id: 10))
                                    .and_return(instance_double(ShopifyAPI::Clients::HttpResponse,
                                                                body: { 'orders' => [{ 'id' => 20, 'total_price' => '10.00',
                                                                                       'access_token' => 'secret' }] }))
      expect(service).not_to receive(:snapshot)
      selected = service.select(resource: 'shopify_orders', filters: [input('contact_id', contact.id)])
      expect(selected['selected_ids']).to eq([20])
      expect(selected.dig('selection', 'complete')).to be false
      expect(selected.to_json).not_to include('secret', 'access_token')
      expect(service.read_related(selected, relationship: 'content')['retrieved_count']).to eq(1)
      role = create(:custom_role, account: account, permissions: ['report_manage'])
      account.account_users.find_by!(user: user).update!(custom_role: role)
      expect { service.authorize_manifest!(selected) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it 'requires clarification when multiple customers match and does not fetch orders' do
      customers = [{ 'id' => 1, 'email' => contact.email }, { 'id' => 2, 'email' => contact.email }]
      allow(client).to receive(:get).with(path: 'customers/search.json', query: anything)
                                    .and_return(instance_double(ShopifyAPI::Clients::HttpResponse, body: { 'customers' => customers }))
      expect(client).not_to receive(:get).with(path: 'orders.json', query: anything)
      expect { service.select(resource: 'shopify_orders', filters: [input('contact_id', contact.id)]) }
        .to raise_error(ArgumentError, 'needs_clarification:shopify_customer_identity')
    end

    it 'rejects cross-account contacts and disabled integrations before calling Shopify' do
      expect(client).not_to receive(:get)
      expect do
        service.select(resource: 'shopify_orders', filters: [input('contact_id', create(:contact).id)])
      end.to raise_error(ActiveRecord::RecordNotFound)
      hook.update!(status: :disabled)
      expect { service.select(resource: 'shopify_orders', filters: [input('contact_id', contact.id)]) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  it 'matches WhatsApp delivery metrics, and denies unsupported channels and ordinary users' do
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook').to_return(status: 200)
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: { waba_templates: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
    account.enable_features!('whatsapp_campaign')
    campaign = create(:campaign, :whatsapp, account: account, campaign_type: :one_off)
    account.account_users.find_by!(user: user).update!(role: :administrator)
    %w[read delivered sent failed skipped].each_with_index do |status, index|
      CampaignRecipient.create!(account: account, campaign: campaign, inbox: campaign.inbox, contact: create(:contact, account: account),
                                status: status, source_id: status == 'skipped' ? nil : "remote-#{index}")
    end
    selected = service.select(resource: 'campaign_metrics', filters: [input('campaign_id', campaign.id)])
    expect(selected.fetch('rows').first).to include('audience' => 5, 'sent' => 4, 'delivered' => 2, 'read' => 1, 'failed' => 1, 'skipped' => 1)
    expect(service.read_related(selected, relationship: 'content')['complete']).to be true
    widget_campaign = create(:campaign, account: account)
    expect do
      service.select(resource: 'campaign_metrics', filters: [input('campaign_id', widget_campaign.id)])
    end.to raise_error(Pundit::NotAuthorizedError)
    account.account_users.find_by!(user: user).update!(role: :agent)
    expect { service.select(resource: 'campaign_metrics', filters: [input('campaign_id', campaign.id)]) }.to raise_error(Pundit::NotAuthorizedError)
  end
end
