# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Assistant::AgentRunnerService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:scenario) { create(:captain_scenario, assistant: assistant, enabled: true) }

  let(:mock_runner) { instance_double(Agents::AgentRunner) }
  let(:mock_agent) { instance_double(Agents::Agent) }
  let(:mock_scenario_agent) { instance_double(Agents::Agent) }
  let(:mock_result) { instance_double(Agents::RunResult, output: { 'response' => 'Test response' }, context: nil) }

  let(:message_history) do
    [
      { role: 'user', content: 'Hello there' },
      { role: 'assistant', content: 'Hi! How can I help you?', agent_name: 'Assistant' },
      { role: 'user', content: 'I need help with my account' }
    ]
  end

  before do
    allow(assistant).to receive(:agent).and_return(mock_agent)
    scenarios_relation = instance_double(Captain::Scenario)
    allow(scenarios_relation).to receive(:enabled).and_return([scenario])
    allow(assistant).to receive(:scenarios).and_return(scenarios_relation)
    allow(scenario).to receive(:agent).and_return(mock_scenario_agent)
    allow(Agents::Runner).to receive(:with_agents).and_return(mock_runner)
    allow(mock_runner).to receive(:run).and_return(mock_result)
    allow(mock_runner).to receive(:on_tool_complete).and_return(mock_runner)
    allow(mock_runner).to receive(:on_run_complete).and_return(mock_runner)
    allow(mock_agent).to receive(:register_handoffs)
    allow(mock_scenario_agent).to receive(:register_handoffs)
  end

  describe '#initialize' do
    it 'sets instance variables correctly' do
      service = described_class.new(assistant: assistant, conversation: conversation)

      expect(service.instance_variable_get(:@assistant)).to eq(assistant)
      expect(service.instance_variable_get(:@conversation)).to eq(conversation)
      expect(service.instance_variable_get(:@callbacks)).to eq({})
    end

    it 'accepts callbacks parameter' do
      callbacks = { on_agent_thinking: proc { |x| x } }
      service = described_class.new(assistant: assistant, callbacks: callbacks)

      expect(service.instance_variable_get(:@callbacks)).to eq(callbacks)
    end
  end

  describe '#generate_response' do
    subject(:service) { described_class.new(assistant: assistant, conversation: conversation) }

    it 'builds agents and wires them together' do
      expect(assistant).to receive(:agent).and_return(mock_agent)
      scenarios_relation = instance_double(Captain::Scenario)
      allow(scenarios_relation).to receive(:enabled).and_return([scenario])
      expect(assistant).to receive(:scenarios).and_return(scenarios_relation)
      expect(scenario).to receive(:agent).and_return(mock_scenario_agent)
      expect(mock_agent).to receive(:register_handoffs).with(mock_scenario_agent)
      expect(mock_scenario_agent).to receive(:register_handoffs).with(mock_agent)

      service.generate_response(message_history: message_history)
    end

    it 'creates runner with agents' do
      expect(Agents::Runner).to receive(:with_agents).with(mock_agent, mock_scenario_agent)

      service.generate_response(message_history: message_history)
    end

    it 'runs agent with extracted user message and context' do
      expected_context = hash_including(
        session_id: "#{account.id}_#{conversation.display_id}",
        conversation_history: [
          { role: :user, content: 'Hello there', agent_name: nil },
          { role: :assistant, content: 'Hi! How can I help you?', agent_name: 'Assistant' }
        ],
        state: hash_including(
          account_id: account.id,
          assistant_id: assistant.id,
          conversation: hash_including(id: conversation.id),
          contact: hash_including(id: contact.id)
        )
      )

      expect(mock_runner).to receive(:run).with(
        'I need help with my account',
        context: expected_context,
        max_turns: 100
      )

      service.generate_response(message_history: message_history)
    end

    context 'when the latest user message is multimodal' do
      let(:multimodal_message_history) do
        [
          { role: 'assistant', content: 'Please share a screenshot' },
          {
            role: 'user',
            content: [
              { type: 'text', text: 'What does this error mean?' },
              { type: 'image_url', image_url: { url: 'https://example.com/error.png' } }
            ]
          }
        ]
      end

      it 'passes image attachments to the runner input' do
        expect(mock_runner).to receive(:run) do |input, context:, max_turns:|
          expect(input).to be_a(RubyLLM::Content)
          expect(input.text).to eq('What does this error mean?')
          expect(input.attachments.first.source.to_s).to eq('https://example.com/error.png')
          expect(context[:conversation_history]).to eq([{ role: :assistant, content: 'Please share a screenshot', agent_name: nil }])
          expect(max_turns).to eq(100)
        end

        service.generate_response(message_history: multimodal_message_history)
      end

      it 'preserves multimodal content in earlier history messages' do
        history_with_prior_image = [
          {
            role: 'user',
            content: [
              { type: 'text', text: 'Here is my error screenshot' },
              { type: 'image_url', image_url: { url: 'https://example.com/error.png' } }
            ]
          },
          { role: 'assistant', content: 'I see the error. Try restarting.' },
          { role: 'user', content: 'It still does not work' }
        ]

        expect(mock_runner).to receive(:run) do |input, context:, max_turns:|
          expect(input).to eq('It still does not work')
          # The earlier user message with the image should preserve the multimodal array
          first_history_msg = context[:conversation_history].first
          expect(first_history_msg[:content]).to be_a(Array)
          expect(first_history_msg[:content]).to include(
            { type: 'text', text: 'Here is my error screenshot' },
            { type: 'image_url', image_url: { url: 'https://example.com/error.png' } }
          )
          expect(max_turns).to eq(100)
        end

        service.generate_response(message_history: history_with_prior_image)
      end

      it 'stores multimodal trace payloads in runner context' do
        expect(mock_runner).to receive(:run) do |_input, context:, max_turns:|
          expect(context[:captain_v2_trace_input]).to include('image_url')
          expect(context[:captain_v2_trace_current_input]).to include('image_url')
          expect(max_turns).to eq(100)
        end

        service.generate_response(message_history: multimodal_message_history)
      end
    end

    it 'processes and formats agent result' do
      result = service.generate_response(message_history: message_history)

      expect(result).to eq({ 'response' => 'Test response', 'agent_name' => nil, 'handoff_tool_called' => false })
    end

    context 'when handoff tool was called during agent execution' do
      let(:runner_context) { { captain_v2_handoff_tool_called: true } }
      let(:mock_result) do
        instance_double(Agents::RunResult, output: { 'response' => 'Let me connect you' }, context: runner_context)
      end

      it 'includes handoff_tool_called flag in response' do
        result = service.generate_response(message_history: message_history)

        expect(result).to eq({
                               'response' => 'Let me connect you',
                               'agent_name' => nil,
                               'handoff_tool_called' => true
                             })
      end
    end

    context 'when no scenarios are enabled' do
      before do
        scenarios_relation = instance_double(Captain::Scenario)
        allow(scenarios_relation).to receive(:enabled).and_return([])
        allow(assistant).to receive(:scenarios).and_return(scenarios_relation)
      end

      it 'only uses assistant agent' do
        expect(Agents::Runner).to receive(:with_agents).with(mock_agent)
        expect(mock_agent).not_to receive(:register_handoffs)

        service.generate_response(message_history: message_history)
      end
    end

    context 'when agent result is a string' do
      let(:mock_result) { instance_double(Agents::RunResult, output: 'Simple string response', context: nil) }

      it 'formats string response correctly' do
        result = service.generate_response(message_history: message_history)

        expect(result).to eq({
                               'response' => 'Simple string response',
                               'reasoning' => 'Processed by agent',
                               'agent_name' => nil,
                               'handoff_tool_called' => false
                             })
      end
    end

    context 'when an error occurs' do
      let(:error) { StandardError.new('Test error') }

      before do
        allow(mock_runner).to receive(:run).and_raise(error)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(
          instance_double(ChatwootExceptionTracker, capture_exception: true)
        )
      end

      it 'captures exception and returns error response' do
        expect(ChatwootExceptionTracker).to receive(:new).with(error, account: conversation.account)

        result = service.generate_response(message_history: message_history)

        expect(result).to eq({
                               'response' => 'conversation_handoff',
                               'reasoning' => 'Error occurred: Test error',
                               'handoff_tool_called' => false
                             })
      end

      it 'logs error details' do
        expect(Rails.logger).to receive(:error).with('[Captain V2] AgentRunnerService error: Test error')
        expect(Rails.logger).to receive(:error).with(kind_of(String))

        service.generate_response(message_history: message_history)
      end

      context 'when conversation is nil' do
        subject(:service) { described_class.new(assistant: assistant, conversation: nil) }

        it 'handles missing conversation gracefully' do
          expect(ChatwootExceptionTracker).to receive(:new).with(error, account: nil)

          result = service.generate_response(message_history: message_history)

          expect(result).to eq({
                                 'response' => 'conversation_handoff',
                                 'reasoning' => 'Error occurred: Test error',
                                 'handoff_tool_called' => false
                               })
        end
      end

      context 'when HandoffTool fired before the runner errored' do
        # The stubbed runner never invokes the on_tool_complete callback, so we call
        # track_handoff_usage directly to simulate the flag being set before the raise.
        before do
          allow(mock_runner).to receive(:run) do
            service.send(:track_handoff_usage,
                         Captain::Tools::HandoffTool.new(assistant).name,
                         Captain::Tools::HandoffTool.new(assistant).name,
                         Struct.new(:context).new({}))
            raise error
          end
        end

        it 'surfaces handoff_tool_called in error_response so the job routes to the V2 path' do
          result = service.generate_response(message_history: message_history)

          expect(result).to eq({
                                 'response' => 'conversation_handoff',
                                 'reasoning' => 'Error occurred: Test error',
                                 'handoff_tool_called' => true
                               })
        end
      end
    end
  end

  describe '#build_context' do
    subject(:service) { described_class.new(assistant: assistant, conversation: conversation) }

    it 'builds context with conversation history and state' do
      context = service.send(:build_context, message_history)

      expect(context).to include(
        conversation_history: array_including(
          { role: :user, content: 'Hello there', agent_name: nil },
          { role: :assistant, content: 'Hi! How can I help you?', agent_name: 'Assistant' }
        ),
        state: hash_including(
          account_id: account.id,
          assistant_id: assistant.id
        )
      )
    end

    context 'with multimodal content' do
      let(:multimodal_content) do
        [
          { type: 'text', text: 'Can you help with this image?' },
          { type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } }
        ]
      end

      let(:multimodal_message_history) do
        [{ role: 'user', content: multimodal_content }]
      end

      it 'preserves multimodal arrays in conversation history for image context retention' do
        context = service.send(:build_context, multimodal_message_history)

        expect(context[:conversation_history].first[:content]).to eq(multimodal_content)
      end
    end
  end

  describe '#extract_last_user_message' do
    subject(:service) { described_class.new(assistant: assistant, conversation: conversation) }

    it 'extracts the last user message' do
      result = service.send(:extract_last_user_message, message_history)

      expect(result).to eq('I need help with my account')
    end

    it 'returns multimodal content with image attachments for the runner input' do
      multimodal_message_history = [
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Can you check this screenshot?' },
            { type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } }
          ]
        }
      ]

      result = service.send(:extract_last_user_message, multimodal_message_history)

      expect(result).to be_a(RubyLLM::Content)
      expect(result.text).to eq('Can you check this screenshot?')
      expect(result.attachments.first.source.to_s).to eq('https://example.com/image.jpg')
    end
  end

  describe '#extract_text_from_content' do
    subject(:service) { described_class.new(assistant: assistant, conversation: conversation) }

    it 'extracts text from string content' do
      result = service.send(:extract_text_from_content, 'Simple text')

      expect(result).to eq('Simple text')
    end

    it 'extracts response from hash content' do
      content = { 'response' => 'Hash response' }
      result = service.send(:extract_text_from_content, content)

      expect(result).to eq('Hash response')
    end

    it 'extracts text from multimodal array content' do
      content = [
        { type: 'text', text: 'First part' },
        { type: 'image_url', image_url: { url: 'image.jpg' } },
        { type: 'text', text: 'Second part' }
      ]

      result = service.send(:extract_text_from_content, content)

      expect(result).to eq('First part Second part')
    end
  end

  describe '#dynamic_trace_attributes' do
    subject(:service) { described_class.new(assistant: assistant, conversation: conversation) }

    it 'adds serialized trace input attributes when present in context' do
      context = {
        state: {
          account_id: account.id,
          assistant_id: assistant.id,
          conversation: { id: conversation.id, display_id: conversation.display_id }
        },
        captain_v2_trace_input: '[{"role":"user","content":[{"type":"image_url","image_url":{"url":"https://example.com/image.jpg"}}]}]'
      }
      context_wrapper = Struct.new(:context).new(context)

      attributes = service.send(:dynamic_trace_attributes, context_wrapper)

      expect(attributes['langfuse.trace.input']).to include('image_url')
      expect(attributes['langfuse.observation.input']).to include('image_url')
      expect(attributes['langfuse.user.id']).to eq(account.id.to_s)
    end
  end

  describe '#build_state' do
    subject(:service) { described_class.new(assistant: assistant, conversation: conversation) }

    it 'builds state with assistant and account information' do
      state = service.send(:build_state)

      expect(state).to include(
        account_id: account.id,
        assistant_id: assistant.id,
        assistant_config: assistant.config
      )
    end

    it 'includes conversation attributes when conversation is present' do
      state = service.send(:build_state)

      expect(state[:conversation]).to include(
        id: conversation.id,
        inbox_id: inbox.id,
        contact_id: contact.id,
        status: conversation.status
      )
      expect(state[:channel_type]).to eq(inbox.channel_type)
    end

    it 'includes contact inbox attributes when conversation is present' do
      state = service.send(:build_state)

      expect(state[:contact_inbox]).to include(
        id: conversation.contact_inbox.id,
        hmac_verified: conversation.contact_inbox.hmac_verified
      )
    end

    it 'always includes contact attributes in state for tool access' do
      state = service.send(:build_state)

      expect(state[:contact]).to include(
        id: contact.id,
        name: contact.name,
        email: contact.email
      )
    end

    it 'does not include campaign when conversation has no campaign' do
      state = service.send(:build_state)

      expect(state).not_to have_key(:campaign)
    end

    context 'when conversation has a campaign' do
      let(:campaign) { create(:campaign, account: account, title: 'Summer Sale', message: 'Check out our deals!', description: 'Seasonal promo') }
      let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, campaign: campaign) }

      it 'includes campaign attributes in state' do
        state = service.send(:build_state)

        expect(state[:campaign]).to include(
          id: campaign.id,
          title: 'Summer Sale',
          message: 'Check out our deals!',
          description: 'Seasonal promo'
        )
      end

      it 'only includes attributes defined in CAMPAIGN_STATE_ATTRIBUTES' do
        state = service.send(:build_state)

        expect(state[:campaign].keys).to match_array(described_class::CAMPAIGN_STATE_ATTRIBUTES)
      end
    end

    context 'when conversation is nil' do
      subject(:service) { described_class.new(assistant: assistant, conversation: nil) }

      it 'builds state without conversation and contact' do
        state = service.send(:build_state)

        expect(state).to include(
          account_id: account.id,
          assistant_id: assistant.id,
          assistant_config: assistant.config
        )
        expect(state).not_to have_key(:conversation)
        expect(state).not_to have_key(:contact)
        expect(state).not_to have_key(:campaign)
      end
    end
  end

  describe '#add_usage_metadata_callback' do
    it 'sets credit_used=false when handoff tool is used' do
      service = described_class.new(assistant: assistant, conversation: conversation)
      runner = instance_double(Agents::AgentRunner)
      tool_complete_callback = nil
      run_complete_callback = nil
      span_class = Class.new do
        def set_attribute(*); end
      end
      root_span = instance_double(span_class)
      context_wrapper = Struct.new(:context).new({ __otel_tracing: { root_span: root_span } })

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
      allow(runner).to receive(:on_tool_complete) do |&block|
        tool_complete_callback = block
        runner
      end
      allow(runner).to receive(:on_run_complete) do |&block|
        run_complete_callback = block
        runner
      end

      service.send(:add_usage_metadata_callback, runner)

      tool_complete_callback.call(Captain::Tools::HandoffTool.new(assistant).name, 'ok', context_wrapper)

      expect(root_span).to receive(:set_attribute).with('langfuse.trace.metadata.credit_used', 'false')
      run_complete_callback.call('assistant', nil, context_wrapper)
    end

    it 'registers handoff tracking callback when OTEL is disabled' do
      service = described_class.new(assistant: assistant, conversation: conversation)
      runner = instance_double(Agents::AgentRunner)
      tool_complete_callback = nil

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(false)
      allow(runner).to receive(:on_tool_complete) do |&block|
        tool_complete_callback = block
        runner
      end

      service.send(:add_usage_metadata_callback, runner)

      context_wrapper = Struct.new(:context).new({})

      expect(tool_complete_callback).not_to be_nil
      tool_complete_callback.call(Captain::Tools::HandoffTool.new(assistant).name, 'ok', context_wrapper)

      expect(context_wrapper.context[:captain_v2_handoff_tool_called]).to be true
    end

    it 'does not register OTEL run callback when OTEL is disabled' do
      service = described_class.new(assistant: assistant, conversation: conversation)
      runner = instance_double(Agents::AgentRunner)

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(false)
      allow(runner).to receive(:on_tool_complete).and_return(runner)
      expect(runner).not_to receive(:on_run_complete)

      service.send(:add_usage_metadata_callback, runner)
    end

    it 'sets credit_used=true when handoff tool is not used' do
      service = described_class.new(assistant: assistant, conversation: conversation)
      runner = instance_double(Agents::AgentRunner)
      run_complete_callback = nil
      span_class = Class.new do
        def set_attribute(*); end
      end
      root_span = instance_double(span_class)
      context_wrapper = Struct.new(:context).new({ __otel_tracing: { root_span: root_span } })

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
      allow(runner).to receive(:on_tool_complete).and_return(runner)
      allow(runner).to receive(:on_run_complete) do |&block|
        run_complete_callback = block
        runner
      end

      service.send(:add_usage_metadata_callback, runner)

      expect(root_span).to receive(:set_attribute).with('langfuse.trace.metadata.credit_used', 'true')
      run_complete_callback.call('assistant', nil, context_wrapper)
    end
  end

  describe 'constants' do
    it 'defines conversation state attributes' do
      expect(described_class::CONVERSATION_STATE_ATTRIBUTES).to include(
        :id, :display_id, :inbox_id, :contact_id, :status, :priority
      )
    end

    it 'defines contact state attributes' do
      expect(described_class::CONTACT_STATE_ATTRIBUTES).to include(
        :id, :name, :email, :phone_number, :identifier, :contact_type
      )
    end

    it 'defines campaign state attributes' do
      expect(described_class::CAMPAIGN_STATE_ATTRIBUTES).to include(
        :id, :title, :message, :campaign_type, :description
      )
    end
  end
end
