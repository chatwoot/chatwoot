require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackCompiler do
  subject(:pack) do
    described_class.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/linear')
    ).compile
  end

  it 'compiles the three bounded support tools and keeps selectors setup-only' do
    templates = pack.fetch('templates').index_by { |template| template.fetch('key') }
    setup_operations = pack.fetch('operations').select { |operation| operation.fetch('visibility') == 'setup' }

    expect(templates.keys).to contain_exactly(
      'add_comment_to_linked_issue',
      'create_issue_from_conversation',
      'get_linked_issue_status'
    )
    expect(templates.values).to all(include('model_visible' => true))
    expect(setup_operations.pluck('key')).to contain_exactly('list_team_entities', 'list_teams')
    expect(templates.values.flat_map { |template| template.fetch('recipe').pluck('operation_key') })
      .not_to include('list_team_entities', 'list_teams')
  end

  it 'fixes issue placement in configuration and trusts only conversation-linked issue identities' do
    templates = pack.fetch('templates').index_by { |template| template.fetch('key') }
    create_step = templates.fetch('create_issue_from_conversation').fetch('recipe').first
    linked_steps = %w[get_linked_issue_status add_comment_to_linked_issue].map do |key|
      templates.fetch(key).fetch('recipe').last
    end

    expect(create_step.fetch('bindings')).to include(
      'teamId' => { 'source' => 'configuration', 'path' => 'team_id' },
      'projectId' => { 'source' => 'configuration', 'path' => 'project_id' }
    )
    expect(linked_steps).to all(
      include(
        'bindings' => include(
          'issueId' => { 'source' => 'linear_linked_issue_id', 'step' => 0, 'path' => 'issue_identifier' }
        )
      )
    )
    expect(templates.fetch('create_issue_from_conversation').dig('recipe', 1, 'bindings', 'url'))
      .to eq('source' => 'linear_conversation_url')
  end

  it 'uses only the fixed Linear endpoint and never reads issue descriptions' do
    operations = pack.fetch('operations').index_by { |operation| operation.fetch('key') }
    read_definitions = %w[linked_issues issue_status].map { |key| operations.fetch(key).fetch('definition') }

    expect(operations.values.pluck('request')).to all(
      include('url' => 'https://api.linear.app/graphql', 'encoding' => 'graphql')
    )
    expect(read_definitions).to all(satisfy { |definition| definition.exclude?('description') })
    expect(operations.fetch('linked_issues').fetch('definition')).to include('first: 10')
    expect(pack.fetch('allowed_origins')).to eq(['https://api.linear.app'])
  end
end
