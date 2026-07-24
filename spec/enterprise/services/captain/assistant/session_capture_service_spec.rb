require 'rails_helper'

RSpec.describe Captain::Assistant::SessionCaptureService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:result_message) { create(:message, account: account, conversation: conversation) }

  let(:usage) do
    Agents::RunContext::Usage.new.tap do |u|
      u.input_tokens = 120
      u.output_tokens = 40
      u.total_tokens = 160
    end
  end

  let(:conversation_history) do
    [
      { role: :user, content: 'Hi, my internet is not working' },
      { role: :assistant, content: 'Let me check', agent_name: 'Assistant' },
      { role: :user, content: 'CUST001' },
      { role: :assistant, content: '', agent_name: 'Assistant', tool_calls: [{ 'id' => 'call_1', 'name' => 'faq_lookup' }] },
      { role: :tool, content: 'Restart the modem', tool_call_id: 'call_1' },
      { role: :assistant, content: 'Please restart your modem', agent_name: 'Assistant' }
    ]
  end

  let(:run_context) do
    {
      session_id: "#{account.id}_#{conversation.display_id}",
      current_agent: 'Assistant',
      turn_count: 2,
      conversation_history: conversation_history,
      state: { cw_metadata: { faq_ids: [11, 12], document_ids: [5] } }
    }
  end

  let(:run_result) { Agents::RunResult.new(output: { 'response' => 'Please restart your modem' }, usage: usage, context: run_context) }

  let(:service) do
    described_class.new(
      assistant: assistant,
      conversation: conversation,
      run_result: run_result,
      result_message: result_message,
      credits_consumed: 1.0
    )
  end

  before do
    allow(assistant).to receive(:agent_model).and_return('gpt-5.2')
  end

  describe '#capture' do
    it 'creates the session' do
      expect { service.capture }.to change(Captain::AgentSession, :count).by(1)
    end

    it 'does nothing when there is no run result' do
      service = described_class.new(
        assistant: assistant, conversation: conversation, run_result: nil,
        result_message: result_message, credits_consumed: 1.0
      )

      expect { service.capture }.not_to change(Captain::AgentSession, :count)
    end

    it 'does nothing when the run failed' do
      failed_result = Agents::RunResult.new(output: nil, error: StandardError.new('run failed'), context: run_context, usage: usage)
      service = described_class.new(
        assistant: assistant, conversation: conversation, run_result: failed_result,
        result_message: nil, credits_consumed: 0.0
      )

      expect { service.capture }.not_to change(Captain::AgentSession, :count)
    end

    it 'reports failures without raising' do
      allow(Captain::AgentSession).to receive(:create!).and_raise(StandardError, 'capture failed')
      allow(ChatwootExceptionTracker).to receive(:new).and_call_original

      expect { service.capture }.not_to raise_error
      expect(ChatwootExceptionTracker).to have_received(:new)
    end
  end

  describe '#capture!' do
    it 'creates an assistant session with all attributes' do
      session = service.capture!

      expect(session).to have_attributes(
        account_id: account.id,
        assistant_id: assistant.id,
        subject_id: conversation.id,
        subject_type: 'Conversation',
        result_id: result_message.id,
        result_type: 'Message',
        llm_model: 'openai-gpt-5.2',
        credits_consumed: 1.0,
        faq_ids: [11, 12],
        document_ids: [5],
        scenario_ids: [],
        user_id: nil
      )
      expect(session).to be_session_assistant
    end

    it 'stores the trimmed current turn in run_context' do
      history = service.capture!.run_context
      expect(history.size).to eq(4)
      expect(history.first).to include('role' => 'user', 'content' => 'CUST001')
    end

    it 'stores multimodal content without cached attachment bytes' do
      content = RubyLLM::Content.new('See image', ['https://example.com/image.jpg'])
      content.attachments.first.instance_variable_set(:@content, "\xFF\xD8\xFF\xE0JFIF".b)
      run_context[:conversation_history] = [
        { role: :user, content: content },
        { role: :assistant, content: 'I can see the image', agent_name: 'Assistant' }
      ]

      history = service.capture!.run_context

      expect(history.first).to include(
        'role' => 'user',
        'content' => {
          'text' => 'See image',
          'attachments' => [{ 'type' => 'image', 'source' => 'https://example.com/image.jpg' }]
        }
      )
    end

    it 'stores the full history when it contains no user message' do
      run_context[:conversation_history] = conversation_history.reject { |message| message[:role] == :user }

      history = service.capture!.run_context

      expect(history.size).to eq(4)
    end

    it 'handles a successful run result without context or usage' do
      run_result = Agents::RunResult.new(output: { 'response' => 'Hello' })
      service = described_class.new(
        assistant: assistant, conversation: conversation, run_result: run_result,
        result_message: result_message, credits_consumed: 1.0
      )

      session = service.capture!

      expect(session.result).to eq(result_message)
      expect(session.faq_ids).to eq([])
      expect(session.document_ids).to eq([])
      expect(session.run_context).to eq([])
    end

    it 'extracts every scenario that authored a message in the current turn' do
      first_scenario = create(:captain_scenario, assistant: assistant, account: account)
      second_scenario = create(:captain_scenario, assistant: assistant, account: account)
      run_context[:conversation_history] = [
        { role: :user, content: 'Help with my refund' },
        { role: :assistant, content: '', agent_name: first_scenario.handoff_key, tool_calls: [] },
        { role: :assistant, content: 'Checking', agent_name: second_scenario.handoff_key },
        { role: :assistant, content: 'Done', agent_name: first_scenario.handoff_key }
      ]
      run_context[:current_agent] = 'Assistant'

      expect(service.capture!.scenario_ids).to eq([first_scenario.id, second_scenario.id])
    end

    it 'leaves scenario ids empty for the primary assistant agent' do
      run_context[:current_agent] = 'Assistant'

      expect(service.capture!.scenario_ids).to eq([])
    end

    it 'does not capture a scenario belonging to another assistant' do
      scenario = create(:captain_scenario, assistant: create(:captain_assistant, account: account), account: account)
      run_context[:conversation_history] = [
        { role: :user, content: 'Help' },
        { role: :assistant, content: 'No', agent_name: scenario.handoff_key }
      ]

      expect(service.capture!.scenario_ids).to eq([])
    end
  end
end
