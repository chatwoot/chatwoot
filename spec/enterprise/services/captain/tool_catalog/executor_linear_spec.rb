require 'rails_helper'

RSpec.describe Captain::ToolCatalog::Executor do
  let(:account) { create(:account) }
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/linear')
    ).compile
  end
  let(:hook) do
    create(
      :integrations_hook,
      :linear,
      account: account,
      access_token: 'linear-access-secret',
      settings: { scope: 'read,write', expires_on: 30.minutes.from_now.utc.to_s }
    )
  end
  let(:state) { { conversation: { id: 29, display_id: 104 } } }

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
    stub_const('ENV', ENV.to_hash.merge('FRONTEND_URL' => 'https://app.chatwoot.test'))
  end

  it 'creates an issue in the configured team and project, then links the current conversation' do
    custom_tool = build_tool(
      'create_issue_from_conversation',
      'team_id' => 'team-1',
      'project_id' => 'project-1'
    )
    responses = [
      {
        data: {
          issueCreate: {
            success: true,
            issue: { id: 'issue-1', identifier: 'ENG-123', title: 'Checkout failure' }
          }
        }
      },
      {
        data: {
          attachmentLinkURL: {
            success: true,
            attachment: {
              issue: {
                identifier: 'ENG-123',
                title: 'Checkout failure',
                url: 'https://linear.app/example/issue/ENG-123/checkout-failure',
                state: { name: 'Backlog' },
                internalDescription: 'must-not-reach-model'
              }
            }
          }
        }
      }
    ]
    requests = capture_requests(responses)

    result = described_class.new(custom_tool: custom_tool, state: state).perform(
      title: 'Checkout failure',
      description: 'Customer cannot complete checkout.'
    )

    expect(requests.first.fetch(:variables)).to eq(
      'teamId' => 'team-1',
      'projectId' => 'project-1',
      'title' => 'Checkout failure',
      'description' => 'Customer cannot complete checkout.'
    )
    expect(requests.second.fetch(:variables)).to eq(
      'issueId' => 'issue-1',
      'url' => "https://app.chatwoot.test/app/accounts/#{account.id}/conversations/104",
      'title' => 'Chatwoot conversation'
    )
    expect(result.to_json).not_to include('internalDescription', 'must-not-reach-model')
  end

  it 'resolves comment issue identity only from links on the current conversation' do
    custom_tool = build_tool('add_comment_to_linked_issue', {})
    responses = [
      {
        data: {
          attachmentsForURL: {
            nodes: [
              { issue: { id: 'issue-1', identifier: 'ENG-123', description: 'internal issue details' } },
              { issue: { id: 'issue-2', identifier: 'ENG-456' } }
            ]
          }
        }
      },
      {
        data: {
          commentCreate: {
            success: true,
            comment: {
              id: 'comment-1',
              body: 'Customer confirmed the issue persists.',
              createdAt: '2026-08-24T10:05:00.000Z',
              privateData: 'must-not-reach-model'
            }
          }
        }
      }
    ]
    requests = capture_requests(responses)

    result = described_class.new(custom_tool: custom_tool, state: state).perform(
      issue_identifier: 'eng-456',
      body: 'Customer confirmed the issue persists.'
    )

    expect(requests.first.fetch(:variables)).to eq(
      'url' => "https://app.chatwoot.test/app/accounts/#{account.id}/conversations/104"
    )
    expect(requests.second.fetch(:variables)).to eq(
      'issueId' => 'issue-2',
      'body' => 'Customer confirmed the issue persists.'
    )
    expect(result.to_json).not_to include('privateData', 'internal issue details', 'must-not-reach-model')
  end

  it 'rejects an issue that is not linked before attempting the mutation' do
    custom_tool = build_tool('add_comment_to_linked_issue', {})
    requests = capture_requests(
      [{ data: { attachmentsForURL: { nodes: [{ issue: { id: 'issue-1', identifier: 'ENG-123' } }] } } }]
    )

    expect do
      described_class.new(custom_tool: custom_tool, state: state).perform(
        issue_identifier: 'ENG-999',
        body: 'Do not send this comment.'
      )
    end.to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('binding_unavailable') }
    expect(requests.one?).to be(true)
  end

  it 'refreshes an expired Linear access token before the provider request' do
    hook.update!(
      access_token: 'expired-access-token',
      refresh_token: 'linear-refresh-secret',
      settings: { scope: 'read,write', expires_on: 1.hour.ago.utc.to_s }
    )
    stub_request(:post, 'https://api.linear.app/oauth/token')
      .to_return(
        status: 200,
        body: {
          access_token: 'refreshed-access-token',
          refresh_token: 'rotated-refresh-token',
          expires_in: 7200,
          scope: 'read,write'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    custom_tool = build_tool('get_linked_issue_status', {})
    responses = [
      { data: { attachmentsForURL: { nodes: [{ issue: { id: 'issue-1', identifier: 'ENG-123' } }] } } },
      {
        data: {
          issue: {
            identifier: 'ENG-123',
            title: 'Checkout failure',
            url: 'https://linear.app/example/issue/ENG-123/checkout-failure',
            updatedAt: '2026-08-24T10:00:00.000Z',
            state: { name: 'In Progress' }
          }
        }
      }
    ]
    authorization_headers = []
    allow(SafeFetch).to receive(:fetch) do |_url, **options, &block|
      authorization_headers << options.dig(:headers, 'Authorization')
      body = JSON.generate(responses.shift)
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    described_class.new(custom_tool: custom_tool, state: state).perform(issue_identifier: 'ENG-123')

    expect(authorization_headers).to eq(['Bearer refreshed-access-token', 'Bearer refreshed-access-token'])
    expect(hook.reload.refresh_token).to eq('rotated-refresh-token')
  end

  it 'rejects model-supplied issue IDs before making a provider request' do
    custom_tool = build_tool('get_linked_issue_status', {})
    allow(SafeFetch).to receive(:fetch)

    expect do
      described_class.new(custom_tool: custom_tool, state: state).perform(
        issue_identifier: 'ENG-123',
        issue_id: 'issue-from-another-conversation'
      )
    end.to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('invalid_tool_input') }
    expect(SafeFetch).not_to have_received(:fetch)
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

  def capture_requests(responses)
    requests = []
    allow(SafeFetch).to receive(:fetch) do |url, **options, &block|
      body = JSON.parse(options.fetch(:body))
      requests << { url: url, variables: body.fetch('variables') }
      response = JSON.generate(responses.shift)
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(response), filename: 'response', content_type: 'application/json'))
    end
    requests
  end
end
