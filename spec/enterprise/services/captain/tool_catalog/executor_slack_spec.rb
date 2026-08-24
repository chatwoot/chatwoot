require 'rails_helper'

RSpec.describe Captain::ToolCatalog::Executor do
  let(:account) { create(:account) }
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/slack')
    ).compile
  end
  let(:hook) do
    create(
      :integrations_hook,
      account: account,
      app_id: 'slack',
      access_token: 'slack-access-secret',
      status: 'disabled',
      settings: {
        catalog_connected: true,
        scope: 'channels:read,chat:write,groups:read,reactions:write,users:read.email'
      }
    )
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
  end

  it 'posts only to the configured channel and returns a signed message reference' do
    custom_tool = build_tool('send_message_to_channel', 'channel_id' => 'C012SUPPORT')
    requests = capture_requests(
      [{ ok: true, channel: 'C012SUPPORT', ts: '1724493600.000100', message: { text: 'private echo' } }]
    )

    result = described_class.new(custom_tool: custom_tool).perform(text: 'Customer needs help with checkout.')

    expect(requests.sole).to include(
      url: 'https://slack.com/api/chat.postMessage',
      body: {
        'channel' => 'C012SUPPORT',
        'text' => 'Customer needs help with checkout.',
        'unfurl_links' => false,
        'unfurl_media' => false
      },
      authorization: 'Bearer slack-access-secret'
    )
    expect(result).to include('ok' => true, 'channel' => 'C012SUPPORT', 'ts' => '1724493600.000100')
    expect(result.fetch('message_reference')).to be_present
    expect(result.keys).to contain_exactly('ok', 'channel', 'ts', 'message_reference')
    expect(result.to_json).not_to include('private echo')
  end

  it 'resolves thread identity only from a signed prior tool result' do
    custom_tool = build_tool('reply_to_thread', {})
    reference = message_reference(account_id: account.id, channel: 'C012SUPPORT', timestamp: '1724493600.000100')
    requests = capture_requests([{ ok: true, channel: 'C012SUPPORT', ts: '1724493610.000200' }])

    result = described_class.new(custom_tool: custom_tool).perform(
      message_reference: reference,
      text: 'The support team is investigating.'
    )

    expect(requests.sole.fetch(:body)).to eq(
      'channel' => 'C012SUPPORT',
      'thread_ts' => '1724493600.000100',
      'text' => 'The support team is investigating.',
      'reply_broadcast' => false,
      'unfurl_links' => false,
      'unfurl_media' => false
    )
    expect(result.fetch('message_reference')).not_to eq(reference)
  end

  it 'rejects tampered, cross-account, and cross-conversation references before a provider request' do
    custom_tool = build_tool('add_reaction_to_message', {})
    other_account_reference = message_reference(account_id: create(:account).id, channel: 'C012SUPPORT', timestamp: '1724493600.000100')
    other_conversation_reference = message_reference(
      account_id: account.id,
      conversation_id: 99,
      channel: 'C012SUPPORT',
      timestamp: '1724493600.000100'
    )
    allow(SafeFetch).to receive(:fetch)

    ["#{other_account_reference}tampered", other_account_reference, other_conversation_reference].each do |reference|
      expect do
        described_class.new(custom_tool: custom_tool).perform(message_reference: reference, emoji: 'white_check_mark')
      end.to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('binding_unavailable') }
    end
    expect(SafeFetch).not_to have_received(:fetch)
  end

  it 'adds a bounded reaction to a trusted Slack message' do
    custom_tool = build_tool('add_reaction_to_message', {})
    reference = message_reference(account_id: account.id, channel: 'G012PRIVATE', timestamp: '1724493600.000100')
    requests = capture_requests([{ ok: true }])

    result = described_class.new(custom_tool: custom_tool).perform(message_reference: reference, emoji: 'white_check_mark')

    expect(requests.sole.fetch(:body)).to eq(
      'channel' => 'G012PRIVATE',
      'timestamp' => '1724493600.000100',
      'name' => 'white_check_mark'
    )
    expect(result).to eq('ok' => true)
  end

  it 'projects user lookup responses to minimal mention identity fields' do
    custom_tool = build_tool('find_user_by_email', {})
    requests = capture_requests(
      [
        {
          ok: true,
          user: {
            id: 'U012AGENT',
            name: 'support-agent',
            real_name: 'Support Agent',
            is_bot: false,
            tz: 'Private timezone',
            profile: {
              display_name: 'Support Agent',
              real_name: 'Support Agent',
              email: 'private@example.com',
              image_512: 'https://private.example/avatar.png'
            }
          }
        }
      ]
    )

    result = described_class.new(custom_tool: custom_tool).perform(email: 'agent@example.com')

    expect(requests.sole.fetch(:url)).to eq('https://slack.com/api/users.lookupByEmail?email=agent%40example.com')
    expect(result.dig('user', 'profile')).to eq('display_name' => 'Support Agent', 'real_name' => 'Support Agent')
    expect(result.to_json).not_to include('Private timezone', 'private@example.com', 'image_512')
  end

  it 'rejects model-supplied destinations and invalid emoji before a provider request' do
    custom_tool = build_tool('send_message_to_channel', 'channel_id' => 'C012SUPPORT')
    reaction_tool = build_tool('add_reaction_to_message', {})
    reference = message_reference(account_id: account.id, channel: 'C012SUPPORT', timestamp: '1724493600.000100')
    allow(SafeFetch).to receive(:fetch)

    expect do
      described_class.new(custom_tool: custom_tool).perform(text: 'Do not send', channel: 'C999ATTACKER')
    end.to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('invalid_tool_input') }
    expect do
      described_class.new(custom_tool: reaction_tool).perform(message_reference: reference, emoji: ':wave:')
    end.to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('invalid_tool_input') }
    expect(SafeFetch).not_to have_received(:fetch)
  end

  it 'rejects a successful message response without a trusted message identity' do
    custom_tool = build_tool('send_message_to_channel', 'channel_id' => 'C012SUPPORT')
    capture_requests([{ ok: true, channel: 'C012SUPPORT' }])
    execution = -> { described_class.new(custom_tool: custom_tool).perform(text: 'Provider response is incomplete.') }

    expect(&execution).to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
      expect(error).to have_attributes(category: 'invalid_response', code: 'slack_message_identity_missing')
    end
  end

  private

  def build_tool(template_key, configuration)
    template = pack.fetch('templates').find { |candidate| candidate.fetch('key') == template_key }
    attributes = Captain::ToolCatalog::SnapshotBuilder.new(
      pack: pack,
      entry: { template: template, configuration: configuration },
      integration_hook: hook
    ).attributes
    account.captain_custom_tools.create!(attributes)
  end

  def message_reference(account_id:, channel:, timestamp:, conversation_id: nil)
    Captain::ToolCatalog::SlackMessageReference.new.generate(
      account_id: account_id,
      conversation_id: conversation_id,
      channel: channel,
      timestamp: timestamp
    )
  end

  def capture_requests(responses)
    requests = []
    allow(SafeFetch).to receive(:fetch) do |url, **options, &block|
      requests << {
        url: url,
        body: options[:body].present? ? JSON.parse(options[:body]) : nil,
        authorization: options.dig(:headers, 'Authorization')
      }
      response = JSON.generate(responses.shift)
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(response), filename: 'response', content_type: 'application/json'))
    end
    requests
  end
end
