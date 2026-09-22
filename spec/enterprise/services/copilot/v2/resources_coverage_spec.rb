require 'rails_helper'

RSpec.describe Copilot::V2::Resources do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:membership) { account.account_users.find_by!(user: user) }
  let(:service) { described_class.new(account: account, user: user) }
  let(:inbox) { create(:inbox, account: account) }

  def input(field, value, operator = 'eq')
    { 'field' => field, 'operator' => operator, 'value' => value }
  end

  def admin!
    membership.update!(role: :administrator)
  end

  # Every registered internal resource has an executable member/outsider boundary.
  (Copilot::V2::ResourceRegistry::DEFINITIONS.keys - %w[conversations contacts messages mentions participants notes]).each do |resource|
    it "permits authorized #{resource} selection and rejects a nonmember" do
      admin!
      account.enable_features!('sla')
      expect(service.select(resource: resource)).to include('resource' => resource, 'reference_type' => 'selection')
      outsider = described_class.new(account: account, user: create(:super_admin))
      expect { outsider.select(resource: resource) }.to raise_error(Pundit::NotAuthorizedError)
      Copilot::V2::ResourceRegistry.fetch(resource)[:relationships].each_key do |relationship|
        selection = service.select(resource: resource)
        expect(service.read_related(selection, relationship: relationship)).to include('relationship' => relationship)
        expect { outsider.read_related(selection, relationship: relationship) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  it 'uses assigned inbox visibility and list-safe labels without exposing channel secrets' do
    create(:inbox_member, user: user, inbox: inbox)
    hidden = create(:inbox, account: account)
    create(:label, account: account)
    expect(service.select(resource: 'inboxes')['selected_ids']).to eq([inbox.id])
    expect(service.select(resource: 'inboxes')['selected_ids']).not_to include(hidden.id)
    expect(service.select(resource: 'labels')['rows']).not_to be_empty
    expect(service.select(resource: 'inboxes')['rows'].first.keys).not_to include('hmac_token', 'channel', 'smtp_password', 'imap_password')
  end

  it 'denies administrative settings and campaigns to ordinary users' do
    %w[account_settings inbox_settings working_hours campaigns reports campaign_metrics].each do |resource|
      expect(service.catalog.fetch(resource)).to include('available' => false)
      expect { service.select(resource: resource) }.to raise_error(Pundit::NotAuthorizedError)
    end
    admin!
    settings = service.select(resource: 'inbox_settings')
    expect(settings.fetch('rows').flat_map(&:keys)).not_to include('channel', 'smtp_password', 'imap_password', 'hmac_token')
    expect(service.read_related(settings, relationship: 'working_hours')['complete']).to be true
  end

  it 'supports literal case-insensitive partial text lookups and rejects contains on enums and IDs' do
    bobby = create(:contact, account: account, name: 'Bobby Armstrong')
    percent = create(:contact, account: account, name: 'Bobby 100%_literal')
    expect(service.select(resource: 'contacts',
                          filters: [input('name', 'BOBBY',
                                          'contains')])['selected_ids']).to contain_exactly(bobby.id, percent.id)
    expect(service.select(resource: 'contacts', filters: [input('name', '%_', 'contains')])['selected_ids']).to eq([percent.id])
    expect { service.select(resource: 'contacts', filters: [input('id', '1', 'contains')]) }.to raise_error(ArgumentError)
    expect { service.select(resource: 'articles', filters: [input('status', 'pub', 'contains')]) }.to raise_error(ArgumentError)
    expect(service.catalog.dig('contacts', 'filters', 'name', 'operators')).to include('contains')
  end

  it 'keeps custom-role article gates distinct from REST and reauthorizes portal article expansion' do
    portal = create(:portal, account: account)
    article = create(:article, account: account, portal: portal, title: 'Install Widget', content: 'Widget instructions')
    metadata = service.select(resource: 'articles', fields: %w[id title]).fetch('rows').first
    expect(metadata.keys).to contain_exactly('id', 'title')
    selection = service.select(resource: 'portals')
    expect(service.read_related(selection, relationship: 'articles').dig('items', 0, 'records', 0, 'id')).to eq(article.id)
    content = service.read_related(service.select(resource: 'articles'), relationship: 'content')
    expect(content.dig('items', 0, 'records', 0, 'parts', 0, 'text')).to eq('Widget instructions')
    role = create(:custom_role, account: account, permissions: ['contact_manage'])
    membership.update!(custom_role: role)
    expect(service.catalog.fetch('articles')).to include('available' => false)
    expect { service.read_related(selection, relationship: 'articles') }.to raise_error(Pundit::NotAuthorizedError)
    role.update!(permissions: ['knowledge_base_manage'])
    expect(service.select(resource: 'articles')['selected_ids']).to eq([article.id])
  end

  it 'narrows knowledge by optional Assistant and distinguishes FAQs from available source text' do
    assistant = create(:captain_assistant, account: account)
    another = create(:captain_assistant, account: account)
    document = create(:captain_document, account: account, assistant: assistant, content: nil)
    create(:captain_document, account: account, assistant: another)
    faq = create(:captain_assistant_response, assistant: assistant, documentable: document)
    scoped = described_class.new(account: account, user: user, assistant: assistant)
    selected = scoped.select(resource: 'documents')
    expect(selected['selected_ids']).to eq([document.id])
    content = scoped.read_related(selected, relationship: 'content')
    expect(content.dig('items', 0, 'records', 0, 'limitations')).to include('source_text_unavailable')
    faqs = scoped.read_related(selected, relationship: 'faqs')
    expect(faqs.dig('items', 0, 'records', 0, 'id')).to eq(faq.id)
    expect(faqs.dig('items', 0, 'records', 0, 'limitations')).to include('derived_faq_not_full_source')
    expect(scoped.read_related(scoped.select(resource: 'faqs'), relationship: 'content')['retrieved_count']).to eq(1)
    expect { described_class.new(account: account, user: user, assistant: create(:captain_assistant)).select(resource: 'documents') }
      .to raise_error(Pundit::NotAuthorizedError)
  end

  it 'keeps notifications personal and marks inaccessible referenced conversations unresolved' do
    visible = create(:conversation, account: account, inbox: inbox)
    hidden = create(:conversation, account: account)
    create(:inbox_member, user: user, inbox: inbox)
    own = create(:notification, account: account, user: user, primary_actor: visible)
    denied = create(:notification, account: account, user: user, primary_actor: hidden)
    create(:notification, account: account, user: create(:user, account: account), primary_actor: visible)
    selected = service.select(resource: 'notifications')
    expect(selected['selected_ids']).to contain_exactly(own.id, denied.id)
    expect(service.select(resource: 'notifications', filters: [input('read_at', nil)])['selected_ids']).to contain_exactly(own.id, denied.id)
    evidence = service.read_related(selected, relationship: 'conversation')
    expect(evidence['resolved_ids']).to eq([own.id])
    expect(evidence['unresolved_ids']).to eq([denied.id])
    InboxMember.where(user: user, inbox: inbox).delete_all
    expect { service.authorize_manifest!(evidence) }.to raise_error(Pundit::NotAuthorizedError)
  end

  it 'uses existing SLA deadlines for accessible conversations and gates the feature' do
    account.enable_features!('sla')
    create(:inbox_member, user: user, inbox: inbox)
    contact = create(:contact, account: account, email: 'sla@example.com')
    conversation = create(:conversation, account: account, inbox: inbox, contact: contact)
    policy = create(:sla_policy, account: account, only_during_business_hours: true)
    applied = create(:applied_sla, account: account, conversation: conversation, sla_policy: policy)
    create(:applied_sla, account: account, conversation: create(:conversation, account: account), sla_policy: policy)
    selected = service.select(resource: 'applied_slas')
    expect(selected['selected_ids']).to eq([applied.id])
    expect(selected.dig('rows', 0, 'deadlines')).to eq(applied.due_at_values.as_json)
    expect(service.read_related(selected, relationship: 'deadlines')['retrieved_count']).to eq(1)
    account.disable_features!('sla')
    expect { service.select(resource: 'applied_slas') }.to raise_error(Pundit::NotAuthorizedError)
  end

  Reports::ReportMetricRegistry::METRICS.each_key do |metric|
    it "matches the existing deterministic #{metric} report and denies ordinary agents" do
      conversation = create(:conversation, account: account, inbox: inbox)
      create(:message, account: account, conversation: conversation, message_type: :incoming)
      event = Reports::ReportMetricRegistry.fetch(metric).raw_event_name
      create(:reporting_event, account: account, conversation: conversation, inbox: inbox, name: event, value: 42) if event
      filters = [input('metric', metric.to_s), input('since', 1.day.ago.iso8601), input('until', Time.current.iso8601)]
      expect { service.select(resource: 'reports', filters: filters) }.to raise_error(Pundit::NotAuthorizedError)
      role = create(:custom_role, account: account, permissions: ['report_manage'])
      membership.update!(custom_role: role)
      row = service.select(resource: 'reports', filters: filters).fetch('rows').first
      expected = V2::Reports::Conversations::ReportBuilder.new(account, row.fetch('scope').symbolize_keys).aggregate_value
      expect(row['value']).to eq(expected)
      expect(row['id']).to start_with('report:')
      evidence = service.read_related(service.select(resource: 'reports', filters: filters), relationship: 'content')
      expect(service.authorize_manifest!(evidence)).to be true
    end
  end

  it 'filters conversations by any requested label within the authorized scope' do
    create(:inbox_member, inbox: inbox, user: user)
    selected = create(:conversation, account: account, inbox: inbox)
    selected.update!(label_list: ['priority'])
    hidden = create(:conversation, account: account)
    hidden.update!(label_list: ['priority'])
    create(:conversation, account: account, inbox: inbox)
    capture = service.select(resource: 'conversations', filters: [{ 'field' => 'labels', 'operator' => 'in', 'value' => %w[priority billing] }])
    expect(capture['selected_ids']).to eq([selected.id])
    expect(capture.dig('rows', 0, 'labels')).to eq(['priority'])
  end

  it 'names unsupported capabilities instead of silently returning empty records' do
    expect(service.catalog.dig('leadsquared_search', 'reason')).to eq('unsupported_capability:leadsquared_search')
    expect { service.select(resource: 'shopify_products') }.to raise_error(ArgumentError, 'unsupported_capability:shopify_products')
  end
end
