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
  let(:mock_result) do
    instance_double(
      Agents::RunResult,
      output: {
        'response_parts' => [{ 'text' => 'Test response', 'citation_indexes' => [] }],
        'reasoning' => 'Test reasoning'
      },
      context: nil
    )
  end

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

    it 'accepts the message id it is responding to' do
      service = described_class.new(assistant: assistant, conversation: conversation, responding_to_message_id: 123)

      expect(service.instance_variable_get(:@responding_to_message_id)).to eq(123)
    end

    it 'accepts reply suggestion mode' do
      service = described_class.new(assistant: assistant, source: described_class::REPLY_SUGGESTION_SOURCE)

      expect(service.instance_variable_get(:@source)).to eq('copilot_reply_suggestion')
      expect(service.send(:trace_config)).to include(
        name: 'llm.captain.copilot.agent',
        tags: ['copilot']
      )
    end
  end

  describe '#build_and_wire_agents' do
    it 'keeps only reply-safe tools and excludes scenarios in reply suggestion mode' do
      faq_tool = Captain::Tools::FaqLookupTool.new(assistant)
      handoff_tool = Captain::Tools::HandoffTool.new(assistant)
      get_tool = Captain::Tools::HttpTool.new(assistant, create(:captain_custom_tool, account: account, http_method: 'GET'))
      post_tool = Captain::Tools::HttpTool.new(assistant, create(:captain_custom_tool, account: account, http_method: 'POST'))
      private_note_tool = Captain::Tools::AddPrivateNoteTool.new(assistant)
      assistant_agent = Agents::Agent.new(name: 'assistant', tools: [faq_tool, handoff_tool, get_tool, post_tool, private_note_tool])
      service = described_class.new(
        assistant: assistant,
        conversation: conversation,
        source: described_class::REPLY_SUGGESTION_SOURCE
      )

      allow(assistant).to receive(:agent).and_return(assistant_agent)
      expect(assistant).not_to receive(:scenarios)

      configured_assistant = service.send(:build_and_wire_agents).sole

      expect(configured_assistant.tools).to contain_exactly(faq_tool, get_tool)
      expect(configured_assistant.handoff_agents).to be_empty
    end

    it 'uses the Copilot prompt without changing the Assistant prompt path' do
      assistant_agent = Agents::Agent.new(name: 'assistant')
      service = described_class.new(
        assistant: assistant,
        conversation: conversation,
        source: described_class::REPLY_SUGGESTION_SOURCE
      )
      context = instance_double(Agents::RunContext)

      allow(assistant).to receive(:agent).and_return(assistant_agent)
      expect(assistant).not_to receive(:scenarios)
      expect(assistant).to receive(:agent_instructions)
        .with(context, prompt_template: 'copilot_reply_suggestion')
        .and_return('Copilot instructions')

      configured_assistant = service.send(:build_and_wire_agents).first

      expect(configured_assistant.instructions.call(context)).to eq('Copilot instructions')
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
        max_turns: 10
      )

      service.generate_response(message_history: message_history)
    end

    it 'adds the responding message id to the runner state' do
      service = described_class.new(assistant: assistant, conversation: conversation, responding_to_message_id: 123)

      expect(mock_runner).to receive(:run).with(
        'I need help with my account',
        context: hash_including(state: hash_including(responding_to_message_id: 123)),
        max_turns: 10
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
          expect(max_turns).to eq(10)
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
          expect(max_turns).to eq(10)
        end

        service.generate_response(message_history: history_with_prior_image)
      end

      it 'stores multimodal trace payloads in runner context' do
        expect(mock_runner).to receive(:run) do |_input, context:, max_turns:|
          expect(context[:captain_v2_trace_input]).to include('image_url')
          expect(context[:captain_v2_trace_current_input]).to include('image_url')
          expect(max_turns).to eq(10)
        end

        service.generate_response(message_history: multimodal_message_history)
      end
    end

    it 'processes and formats agent result' do
      result = service.generate_response(message_history: message_history)

      expect(result).to eq({
                             'response_parts' => [{ 'text' => 'Test response', 'citation_indexes' => [] }],
                             'response' => 'Test response',
                             'reasoning' => 'Test reasoning',
                             'agent_name' => nil,
                             'handoff_tool_called' => false
                           })
    end

    it 'exposes the raw run result via last_run_result' do
      service.generate_response(message_history: message_history)

      expect(service.last_run_result).to eq(mock_result)
    end

    context 'when handoff tool was called during agent execution' do
      let(:runner_context) { { captain_v2_handoff_tool_called: true } }
      let(:mock_result) do
        instance_double(
          Agents::RunResult,
          output: {
            'response_parts' => [{ 'text' => 'Let me connect you', 'citation_indexes' => [] }],
            'reasoning' => 'A human is needed'
          },
          context: runner_context
        )
      end

      it 'includes handoff_tool_called flag in response' do
        result = service.generate_response(message_history: message_history)

        expect(result).to eq({
                               'response' => 'Let me connect you',
                               'response_parts' => [{ 'text' => 'Let me connect you', 'citation_indexes' => [] }],
                               'reasoning' => 'A human is needed',
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
                               'response_parts' => [{ 'text' => 'Simple string response', 'citation_indexes' => [] }],
                               'reasoning' => 'Processed by agent',
                               'agent_name' => nil,
                               'handoff_tool_called' => false
                             })
      end
    end

    context 'when structured response parts contain invalid values' do
      let(:assistant) { create(:captain_assistant, account: account, config: { 'feature_citation' => true }) }
      let(:mock_result) do
        instance_double(
          Agents::RunResult,
          output: {
            'response_parts' => [
              { 'text' => '  First part  ', 'citation_indexes' => [2, 2, 0, '1', 'https://model.example/source'] },
              { 'text' => '   ', 'citation_indexes' => [1] },
              'invalid',
              { 'text' => 'Second part', 'citation_indexes' => [1] }
            ],
            'reasoning' => 'Test reasoning'
          },
          context: nil
        )
      end

      it 'keeps valid ordered parts and derives the compatibility response string' do
        result = service.generate_response(message_history: message_history)

        expect(result['response_parts']).to eq(
          [
            { 'text' => 'First part', 'citation_indexes' => [2] },
            { 'text' => 'Second part', 'citation_indexes' => [1] }
          ]
        )
        expect(result['response']).to eq("First part\n\nSecond part")
      end
    end

    context 'when citations are disabled' do
      let(:mock_result) do
        instance_double(
          Agents::RunResult,
          output: {
            'response_parts' => [{ 'text' => 'FAQ-backed response', 'citation_indexes' => [1] }],
            'reasoning' => 'Test reasoning'
          },
          context: nil
        )
      end

      it 'discards model-provided citation indexes' do
        result = service.generate_response(message_history: message_history)

        expect(result['response_parts']).to eq(
          [{ 'text' => 'FAQ-backed response', 'citation_indexes' => [] }]
        )
      end
    end

    context 'when a structured response exceeds the channel limit' do
      let(:channel_limit_rewrite) do
        original_model_output = {
          'response_parts' => [
            { 'text' => 'The first answer has more detail than this channel can accept.', 'citation_indexes' => [2] },
            { 'text' => 'The second answer also has more detail than this channel can accept.', 'citation_indexes' => [1] }
          ],
          'reasoning' => 'Used two FAQ results'
        }
        rewritten_model_output = {
          'response_parts' => [
            { 'text' => 'Short first answer.', 'citation_indexes' => [2] },
            { 'text' => 'Short second answer.', 'citation_indexes' => [1] }
          ],
          'reasoning' => 'Shortened both parts'
        }
        runner_context = {
          session_id: "#{account.id}_#{conversation.display_id}",
          state: { Captain::Assistant::CITATION_SOURCES_STATE_KEY => { 1 => 101, 2 => 202 } },
          conversation_history: [{ role: :assistant, content: original_model_output }]
        }
        runner_messages = [{ role: :assistant, content: original_model_output }]

        {
          original_run_result: Agents::RunResult.new(output: original_model_output, messages: runner_messages, context: runner_context),
          rewrite_run_result: Agents::RunResult.new(output: rewritten_model_output, messages: [], context: {}),
          citation_urls: {
            1 => 'https://help.example.com/first',
            2 => 'https://help.example.com/second'
          },
          runner_context: runner_context
        }
      end
      let(:mock_result) { channel_limit_rewrite[:original_run_result] }

      before do
        allow(assistant).to receive(:config).and_return('feature_citation' => true)
        allow(assistant).to receive(:customer_visible_citation_urls).and_return(channel_limit_rewrite[:citation_urls])
        allow(Captain::MessageLengthLimit).to receive(:for).with(conversation).and_return(140)
        allow(mock_runner).to receive(:run).and_return(mock_result, channel_limit_rewrite[:rewrite_run_result])
      end

      it 'reserves space for rendered citations and restores their original indexes' do
        original_response_parts = Captain::Assistant::ResponseParts.from_response(mock_result.output)
        original_customer_message = original_response_parts.customer_message_content(citation_urls: channel_limit_rewrite[:citation_urls])
        citation_markup_length = original_customer_message.length - original_response_parts.plain_text.length
        response_text_limit = 140 - citation_markup_length

        expect(original_response_parts.plain_text.length).to be < 140
        expect(original_customer_message.length).to be > 140

        result = service.generate_response(message_history: message_history)

        expect(result['response_parts']).to eq(
          [
            { 'text' => 'Short first answer.', 'citation_indexes' => [2] },
            { 'text' => 'Short second answer.', 'citation_indexes' => [1] }
          ]
        )
        expect(channel_limit_rewrite[:runner_context][:conversation_history].last[:content]['response_parts']).to eq(result['response_parts'])
        expect(
          Captain::Assistant::ResponseParts.from_response(result).customer_message_content(
            citation_urls: channel_limit_rewrite[:citation_urls]
          ).length
        ).to be <= 140
        expect(mock_runner).to have_received(:run).with(
          include(
            "must be at most #{response_text_limit} characters",
            'Keep the same number and order of response parts',
            '"citation_indexes":[2]',
            '"citation_indexes":[1]'
          ),
          context: hash_including(state: channel_limit_rewrite[:runner_context][:state]),
          max_turns: 1
        )
        expect(mock_runner).not_to have_received(:run).with(include('help.example.com'), any_args)
      end

      it 'rejects a rewrite that changes the response part citation order' do
        channel_limit_rewrite[:rewrite_run_result].output['response_parts'].reverse!
        allow(ChatwootExceptionTracker).to receive(:new).and_return(
          instance_double(ChatwootExceptionTracker, capture_exception: true)
        )

        result = service.generate_response(message_history: message_history)

        expect(result['response']).to eq('conversation_handoff')
        expect(result['reasoning']).to eq('Error occurred: Captain response rewrite changed the response part citation order')
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
                               'response_parts' => [{ 'text' => 'conversation_handoff', 'citation_indexes' => [] }],
                               'reasoning' => 'Error occurred: Test error',
                               'error' => true,
                               'error_reason' => 'standard_error',
                               'handoff_tool_called' => false
                             })
      end

      it 'logs error details' do
        expect(Rails.logger).to receive(:error).with('[Captain V2] AgentRunnerService error: Test error')
        expect(Rails.logger).to receive(:error).with(kind_of(String))

        service.generate_response(message_history: message_history)
      end

      it 'leaves last_run_result nil' do
        service.generate_response(message_history: message_history)

        expect(service.last_run_result).to be_nil
      end

      context 'when conversation is nil' do
        subject(:service) { described_class.new(assistant: assistant, conversation: nil) }

        it 'handles missing conversation gracefully' do
          expect(ChatwootExceptionTracker).to receive(:new).with(error, account: nil)

          result = service.generate_response(message_history: message_history)

          expect(result).to eq({
                                 'response' => 'conversation_handoff',
                                 'response_parts' => [{ 'text' => 'conversation_handoff', 'citation_indexes' => [] }],
                                 'reasoning' => 'Error occurred: Test error',
                                 'error' => true,
                                 'error_reason' => 'standard_error',
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
                                 'response_parts' => [{ 'text' => 'conversation_handoff', 'citation_indexes' => [] }],
                                 'reasoning' => 'Error occurred: Test error',
                                 'error' => true,
                                 'error_reason' => 'standard_error',
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

    it 'joins structured response parts from hash content' do
      content = {
        'response_parts' => [
          { 'text' => 'First response part', 'citation_indexes' => [1] },
          { 'text' => 'Second response part', 'citation_indexes' => [] }
        ]
      }
      result = service.send(:extract_text_from_content, content)

      expect(result).to eq("First response part\n\nSecond response part")
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

  describe 'InstrumentationAttributeProvider' do
    subject(:provider) { Captain::Assistant::InstrumentationAttributeProvider.new(service) }

    let(:service) { described_class.new(assistant: assistant, conversation: conversation) }

    it 'delegates root trace attributes to the service' do
      context = {
        state: {
          account_id: account.id,
          assistant_id: assistant.id,
          conversation: { id: conversation.id, display_id: conversation.display_id }
        }
      }
      context_wrapper = Struct.new(:context).new(context)

      attributes = provider.call(context_wrapper)

      expect(attributes).to include(
        'langfuse.user.id' => account.id.to_s,
        'langfuse.trace.metadata.assistant_id' => assistant.id.to_s
      )
    end

    it 'marks final response generations for observation-level evaluators' do
      message = instance_double(RubyLLM::Message, tool_calls: {})

      attributes = provider.generation_attributes(nil, nil, message)

      expect(attributes['langfuse.observation.metadata.generation_stage']).to eq('final_response')
      expect(attributes).not_to have_key('langfuse.observation.metadata.discarded')
    end

    it 'marks a protected generation as not discarded when no newer message has arrived' do
      responding_to_message = create(:message, conversation: conversation, message_type: :incoming)
      runner_service = described_class.new(assistant: assistant, conversation: conversation,
                                           responding_to_message_id: responding_to_message.id)
      attribute_provider = Captain::Assistant::InstrumentationAttributeProvider.new(runner_service)
      message = instance_double(RubyLLM::Message, tool_calls: {})

      attributes = attribute_provider.generation_attributes(nil, nil, message)

      expect(attributes['langfuse.observation.metadata.discarded']).to eq('false')
    end

    it 'marks tool call generations separately from final responses' do
      tool_call = instance_double(RubyLLM::ToolCall)
      message = instance_double(RubyLLM::Message, tool_calls: { 'call_1' => tool_call })

      attributes = provider.generation_attributes(nil, nil, message)

      expect(attributes['langfuse.observation.metadata.generation_stage']).to eq('tool_call')
    end

    it 'marks a generation as discarded when a newer message has arrived' do
      responding_to_message = create(:message, conversation: conversation, message_type: :incoming)
      runner_service = described_class.new(assistant: assistant, conversation: conversation,
                                           responding_to_message_id: responding_to_message.id)
      attribute_provider = Captain::Assistant::InstrumentationAttributeProvider.new(runner_service)
      message = instance_double(RubyLLM::Message, tool_calls: {})
      create(:message, conversation: conversation, message_type: :incoming)

      attributes = attribute_provider.generation_attributes(nil, nil, message)

      expect(attributes['langfuse.observation.metadata.discarded']).to eq('true')
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

    it 'includes labels from a persisted conversation' do
      conversation.label_list.add('lang_en')
      conversation.save!
      conversation.reload

      state = service.send(:build_state)

      expect(state.dig(:conversation, :label_list)).to contain_exactly('lang_en')
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
      allow(runner).to receive(:on_run_complete).and_return(runner)

      service.send(:add_usage_metadata_callback, runner)

      context_wrapper = Struct.new(:context).new({ state: { captain_v2_handoff_tool_completed: true } })

      expect(tool_complete_callback).not_to be_nil
      tool_complete_callback.call(Captain::Tools::HandoffTool.new(assistant).name, 'ok', context_wrapper)

      expect(context_wrapper.context[:captain_v2_handoff_tool_called]).to be true
      expect(service.handoff_completed?).to be true
    end

    it 'tracks discarded responses when OTEL is disabled' do
      responding_to_message = create(:message, conversation: conversation, message_type: :incoming)
      service = described_class.new(assistant: assistant, conversation: conversation, responding_to_message_id: responding_to_message.id)
      runner = instance_double(Agents::AgentRunner)
      run_complete_callback = nil

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(false)
      allow(runner).to receive(:on_tool_complete).and_return(runner)
      allow(runner).to receive(:on_run_complete) do |&block|
        run_complete_callback = block
        runner
      end

      service.send(:add_usage_metadata_callback, runner)
      create(:message, conversation: conversation, message_type: :incoming)
      run_complete_callback.call('assistant', nil, Struct.new(:context).new({}))

      expect(service.response_discarded?).to be true
    end

    it 'does not register a run callback when OTEL and burst protection are disabled' do
      service = described_class.new(assistant: assistant, conversation: conversation)
      runner = instance_double(Agents::AgentRunner)

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(false)
      allow(runner).to receive(:on_tool_complete).and_return(runner)
      expect(runner).not_to receive(:on_run_complete)

      service.send(:add_usage_metadata_callback, runner)
    end

    it 'leaves final credit and discard metadata to the reply suggestion service' do
      service = described_class.new(
        assistant: assistant,
        conversation: conversation,
        source: described_class::REPLY_SUGGESTION_SOURCE
      )
      runner = instance_double(Agents::AgentRunner)

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
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

    it 'marks the trace discarded and does not use credit when a newer message arrived' do
      responding_to_message = create(:message, conversation: conversation, message_type: :incoming)
      service = described_class.new(assistant: assistant, conversation: conversation, responding_to_message_id: responding_to_message.id)
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
      create(:message, conversation: conversation, message_type: :incoming)

      expect(root_span).to receive(:set_attribute).with('langfuse.trace.metadata.discarded', 'true')
      expect(root_span).to receive(:set_attribute).with('langfuse.trace.metadata.credit_used', 'false')
      run_complete_callback.call('assistant', nil, context_wrapper)

      expect(service.response_discarded?).to be true
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
