require 'rails_helper'

RSpec.describe Captain::Copilot::TurnTranscript do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:chat) do
    instance_double(RubyLLM::Chat, model: instance_double(RubyLLM::Model, id: 'gpt-4.1-mini'),
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
end
