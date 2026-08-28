require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackCompiler do
  subject(:pack) do
    described_class.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/slack')
    ).compile
  end

  it 'compiles four bounded tools and keeps workspace discovery setup-only' do
    templates = pack.fetch('templates').index_by { |template| template.fetch('key') }
    setup_operations = pack.fetch('operations').select { |operation| operation.fetch('visibility') == 'setup' }

    expect(templates.keys).to contain_exactly(
      'add_reaction_to_message',
      'find_user_by_email',
      'reply_to_thread',
      'send_message_to_channel'
    )
    expect(templates.values).to all(include('model_visible' => true))
    expect(setup_operations.pluck('key')).to contain_exactly('auth_test', 'list_channels')
    expect(templates.values.flat_map { |template| template.fetch('recipe').pluck('operation_key') })
      .not_to include('auth_test', 'list_channels')
  end

  it 'fixes the destination during setup and trusts signed references for follow-up writes' do
    templates = pack.fetch('templates').index_by { |template| template.fetch('key') }
    send_bindings = templates.fetch('send_message_to_channel').dig('recipe', 0, 'bindings')
    reply_bindings = templates.fetch('reply_to_thread').dig('recipe', 0, 'bindings')
    reaction_bindings = templates.fetch('add_reaction_to_message').dig('recipe', 0, 'bindings')

    expect(send_bindings.fetch('channel')).to eq('source' => 'configuration', 'path' => 'channel_id')
    expect(reply_bindings).to include(
      'channel' => { 'source' => 'slack_reference_channel', 'path' => 'message_reference' },
      'thread_ts' => { 'source' => 'slack_reference_timestamp', 'path' => 'message_reference' }
    )
    expect(reaction_bindings).to include(
      'channel' => { 'source' => 'slack_reference_channel', 'path' => 'message_reference' },
      'timestamp' => { 'source' => 'slack_reference_timestamp', 'path' => 'message_reference' }
    )
  end

  it 'uses only fixed Slack Web API methods and contains no history or search operation' do
    operations = pack.fetch('operations')
    requests = operations.pluck('request')
    definitions = operations.pluck('definition').to_json

    expect(requests.pluck('url')).to all(start_with('https://slack.com/api/'))
    expect(pack.fetch('allowed_origins')).to eq(['https://slack.com'])
    expect(definitions).not_to include('history', 'search')
    expect(operations.find { |operation| operation.fetch('key') == 'lookup_user_by_email' }.fetch('scopes'))
      .to eq(['users:read', 'users:read.email'])
    expect(operations.find { |operation| operation.fetch('key') == 'send_message' }.fetch('scopes'))
      .to include('channels:join')
  end
end
