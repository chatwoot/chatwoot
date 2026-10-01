require 'rails_helper'

RSpec.describe Captain::Playground::RunDetails do
  let(:configuration) do
    instance_double(
      Captain::Playground::Configuration,
      knowledge_text: 'temporary knowledge',
      handler_for: { type: 'assistant', id: nil, title: 'Support assistant', temporary: false }
    )
  end

  it 'records chronological tool and handoff events with redacted, truncated previews' do
    details = described_class.new(configuration: configuration)
    callbacks = details.callbacks

    callbacks[:on_tool_start].call('captain--tools--update_priority', { priority: 'high', api_token: 'secret' }, nil)
    callbacks[:on_tool_complete].call('captain--tools--update_priority', 'x' * 600, nil)
    callbacks[:on_agent_handoff].call('assistant', 'refund_agent', 'handoff', nil)
    result = details.to_h(agent_name: 'refund_agent')

    expect(result[:events].pluck(:type)).to eq(%w[tool handoff])
    expect(result[:events].first).to include(
      name: 'update_priority',
      status: 'completed',
      arguments: { priority: 'high', api_token: '[REDACTED]' }
    )
    expect(result[:events].first[:result_preview].length).to eq(500)
    expect(result[:temporary_knowledge_attached]).to be true
    expect(result[:duration_ms]).to be_a(Integer)
  end

  it 'marks callback errors as failed tool events' do
    details = described_class.new(configuration: configuration)

    details.callbacks[:on_tool_complete].call('custom--tool', 'ERROR: request failed', nil)

    expect(details.to_h(agent_name: 'assistant')[:events].first[:status]).to eq('failed')
  end

  it 'redacts credentials embedded in serialized tool results' do
    details = described_class.new(configuration: configuration)
    serialized_result = {
      authorization: 'Bearer internal-token',
      payload: { api_key: 'private-key', value: 'safe' }
    }.to_json

    details.callbacks[:on_tool_complete].call('custom--tool', serialized_result, nil)

    preview = details.to_h(agent_name: 'assistant')[:events].first[:result_preview]
    expect(preview).to include('[REDACTED]', 'safe')
    expect(preview).not_to include('internal-token', 'private-key')
  end

  it 'redacts quoted credential headers from non-JSON tool output and handoff reasons' do
    details = described_class.new(configuration: configuration)
    sensitive_text = 'request failed with "Authorization": "Bearer internal-token"'

    details.callbacks[:on_tool_complete].call('custom--tool', sensitive_text, nil)
    details.callbacks[:on_agent_handoff].call('assistant', 'refund_agent', sensitive_text, nil)

    result = details.to_h(agent_name: 'assistant')
    public_values = result[:events].pluck(:result_preview, :reason).flatten.compact
    expect(public_values).to all(satisfy { |value| value.exclude?('internal-token') })
  end
end
