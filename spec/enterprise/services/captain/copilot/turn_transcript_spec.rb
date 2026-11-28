require 'rails_helper'

RSpec.describe Captain::Copilot::TurnTranscript do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:context_window) { 128_000 }
  let(:chat) do
    instance_double(RubyLLM::Chat, model: instance_double(RubyLLM::Model, id: 'gpt-4.1-mini', context_window: context_window),
                                   provider: instance_double(RubyLLM::Provider, slug: 'openai'), messages: [])
  end

  before do
    allow(chat).to receive(:add_message) { |attributes| chat.messages << RubyLLM::Message.new(attributes) }
  end

  def turn_for(content)
    message = thread.copilot_messages.create!(message_type: :user, message: { content: content })
    CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message)
  end

  it 'tells the model that an earlier turn was stopped, which the thread shows without a reply' do
    turn_for('Review the billing conversations').stop
    current = turn_for('How many are open?')

    described_class.new(current, chat, protocol: :chat_completions).load

    expect(chat.messages.map { |message| [message.role, message.content] }).to eq(
      [[:user, 'Review the billing conversations'], [:assistant, I18n.t('captain.copilot.stopped')], [:user, 'How many are open?']]
    )
  end

  describe 'replaying earlier turns' do
    let(:identity) { { 'model' => 'gpt-4.1-mini', 'provider' => 'openai', 'protocol' => 'chat_completions', 'endpoint' => nil } }
    let(:result) { { 'issues' => Array.new(50) { |index| { 'key' => "SUP-#{index}", 'summary' => 'x' * 200 } } } }

    def finished_turn(content)
      turn_for(content).tap do |prior|
        prior.tool_calls.create!(call_id: 'call-1', name: 'search_contacts', status: :completed, result: result)
        messages = [{ role: 'tool', tool_call_id: 'call-1', content: JSON.generate(result) }]
        prior.update!(status: :completed, transcript: { identity: identity, messages: messages })
      end
    end

    it 'shows a large result of a replayed turn as its handle, which read_tool_result can open' do
      tool_call = finished_turn('List the issues').tool_calls.first
      described_class.new(turn_for('Which is first?'), chat, protocol: :chat_completions).load

      tool_message = chat.messages.find { |message| message.role == :tool }
      expect(JSON.parse(tool_message.content)).to include('result_id' => tool_call.id, 'tool' => 'search_contacts')
    end

    it 'outlines an earlier turn that does not fit the history budget instead of replaying it' do
      finished_turn('List the issues')
      allow(chat.model).to receive(:context_window).and_return(100)
      described_class.new(turn_for('Which is first?'), chat, protocol: :chat_completions).load

      expect(chat.messages.map(&:role)).to eq(%i[user assistant user])
      expect(JSON.parse(chat.messages.second.content)['tool_calls'].first).to include('name' => 'search_contacts')
    end
  end
end
