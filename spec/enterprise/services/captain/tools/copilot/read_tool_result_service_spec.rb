require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::ReadToolResultService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant) }
  let(:run) do
    message = thread.copilot_messages.create!(message_type: :user, message: { content: 'Which component has the most open bugs?' })
    CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message)
  end
  let(:tool) { described_class.new(assistant, user: user, run: run, lease_token: nil) }
  let(:issues) do
    [{ 'key' => 'SUP-1', 'type' => 'Bug', 'status' => 'To Do', 'components' => [{ 'name' => 'API' }, { 'name' => 'Widget' }] },
     { 'key' => 'SUP-2', 'type' => 'Bug', 'status' => 'Done', 'components' => [{ 'name' => 'API' }] },
     { 'key' => 'SUP-3', 'type' => 'Bug', 'status' => 'In Review', 'components' => [{ 'name' => 'API' }], 'assignee' => nil },
     { 'key' => 'SUP-4', 'type' => 'Task', 'status' => 'To Do', 'components' => [], 'assignee' => { 'name' => 'Dana' } }]
  end
  let(:saved) { run.tool_calls.create!(call_id: 'call-1', name: 'jira_export', status: :completed, result: { 'issues' => issues }) }

  it 'counts the items that meet every condition, once for each value of a list field' do
    result = tool.execute(result_id: saved.id, path: 'issues', count_by: 'components.name',
                          where: [{ field: 'type', operator: 'equals', value: 'bug' }, { field: 'status', operator: 'not_equals', value: 'done' }])

    expect(result).to eq(total_matching: 2, distinct_values: 2, counts: { 'API' => 2, 'Widget' => 1 })
  end

  it 'keeps items by one_of and empty, and returns only the fields asked for' do
    result = tool.execute(result_id: saved.id, path: 'issues', fields: %w[key],
                          where: [{ field: 'status', operator: 'one_of', values: ['To Do', 'In Review'] },
                                  { field: 'assignee.name', operator: 'empty' }])

    expect(result).to eq(total_matching: 2, offset: 0, returned: 2, items: [{ 'key' => 'SUP-1' }, { 'key' => 'SUP-3' }])
  end

  it 'returns a long list in parts that each fit the model view, with the offset of the next part' do
    saved.update!(result: { 'issues' => Array.new(40) { |index| { 'key' => "SUP-#{index}", 'body' => 'x' * 2_000 } } })
    first = tool.execute(result_id: saved.id, path: 'issues')
    second = tool.execute(result_id: saved.id, path: 'issues', offset: first[:next_offset])

    expect(JSON.generate(first).size).to be <= Captain::Copilot::ToolResultView::LIMIT
    expect(first[:total_matching]).to eq(40)
    expect(second[:items].first['key']).to eq("SUP-#{first[:returned]}")
  end

  it 'searches the lines of a text result' do
    saved.update!(result: "Customer: hello\nAgent: the tracking number is TRK-1\nCustomer: thanks")

    expect(tool.execute(result_id: saved.id, search: 'tracking')).to include(total_lines: 1, text: "Agent: the tracking number is TRK-1\n")
  end

  it 'reads no result from another thread' do
    other_thread = create(:captain_copilot_thread, account: account, user: user, assistant: assistant)
    other_message = other_thread.copilot_messages.create!(message_type: :user, message: { content: 'Hi' })
    other_run = CopilotRun::Turn.create!(account: account, user: user, copilot_thread: other_thread, copilot_message: other_message)
    other = other_run.tool_calls.create!(call_id: 'call-9', name: 'jira_export', status: :completed, result: { 'issues' => issues })

    expect(tool.execute(result_id: other.id)).to eq(error: "No saved result with result_id #{other.id} in this thread")
  end
end
