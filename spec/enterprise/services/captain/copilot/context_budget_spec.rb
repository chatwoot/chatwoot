require 'rails_helper'

RSpec.describe Captain::Copilot::ContextBudget do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:run) do
    message = thread.copilot_messages.create!(message_type: :user, message: { content: 'Compare the exports' })
    CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message)
  end
  let(:messages) { [] }
  let(:chat) { instance_double(RubyLLM::Chat, model: instance_double(RubyLLM::Model, context_window: 100_000), messages: messages) }
  let(:budget) { described_class.new(chat, thread_id: thread.id, run_id: run.id) }

  def add_result(call_id, characters)
    run.tool_calls.create!(call_id: call_id, name: 'get_conversation', status: :completed, result: 'x' * characters)
    messages << RubyLLM::Message.new(role: :tool, tool_call_id: call_id, content: 'x' * characters)
  end

  it 'leaves the prompt alone while the last response and what followed it fit half the window' do
    messages << RubyLLM::Message.new(role: :assistant, content: '', input_tokens: 30_000, output_tokens: 100)
    add_result('call-1', 30_000)

    expect(budget.fit!).to be(false)
    expect(messages.last.content.size).to eq(30_000)
  end

  it 'replaces older large results with handles, keeping the newest the model has not read' do
    add_result('call-1', 30_000)
    messages << RubyLLM::Message.new(role: :assistant, content: '', input_tokens: 45_000, output_tokens: 100)
    add_result('call-2', 30_000)

    expect(budget.fit!).to be(true)
    expect(JSON.parse(messages.first.content)).to include('result_id' => run.tool_calls.find_by(call_id: 'call-1').id)
    expect(messages.last.content.size).to eq(30_000)
  end

  it 'replaces every large result once after the provider refuses the prompt, and not a second time' do
    add_result('call-1', 30_000)
    add_result('call-2', 30_000)

    expect(budget.compact_after_overflow!).to be(true)
    expect(messages.map { |message| message.content.size }).to all(be < described_class::HANDLE_MIN)
    expect(budget.compact_after_overflow!).to be(false)
  end
end
