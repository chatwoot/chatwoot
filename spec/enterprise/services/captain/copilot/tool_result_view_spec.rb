require 'rails_helper'

RSpec.describe Captain::Copilot::ToolResultView do
  let(:tool_call) { instance_double(CopilotToolCall, id: 7, name: 'get_conversation') }

  it 'passes a result under the limit through unchanged' do
    result = { 'contacts' => [{ 'name' => 'Ada' }] }

    expect(described_class.for_model(result, tool_call)).to equal(result)
  end

  it 'passes a large display page through whole, since the model copies it into its reply' do
    display_call = instance_double(CopilotToolCall, id: 8, name: 'display')
    result = { 'table' => 'x' * (described_class::LIMIT * 2) }

    expect(described_class.for_model(result, display_call)).to equal(result)
  end

  it 'shows a large list as an outline with its result_id, the list length and the first item' do
    result = { 'issues' => Array.new(300) { |index| { 'key' => "SUP-#{index}", 'status' => { 'name' => 'Done' }, 'body' => 'x' * 300 } } }
    view = described_class.for_model(result, tool_call)

    expect(view).to include(result_id: 7, characters: JSON.generate(result).size)
    expect(view[:outline]['issues']).to include(list_length: 300)
    expect(view[:outline]['issues'][:first_item]).to include('key' => 'SUP-0', 'status' => { 'name' => 'Done' })
    expect(JSON.generate(view).size).to be < described_class::LIMIT
  end

  it 'shows the start and end of a long text, which hold the oldest and newest messages of a conversation' do
    text = "first line\n#{"middle line\n" * 10_000}last line"
    view = described_class.for_model(text, tool_call)

    expect(view).to include(result_id: 7, lines: 10_002)
    expect(view[:start]).to start_with('first line')
    expect(view[:end]).to end_with('last line')
  end

  it 'outlines JSON a tool returned as text, as MCP servers do' do
    view = described_class.for_model(JSON.generate({ 'rows' => Array.new(5_000) { |index| { 'id' => index } } }), tool_call)

    expect(view[:outline]['rows']).to eq(list_length: 5_000, first_item: { 'id' => 0 })
  end
end
