require 'rails_helper'

RSpec.describe Captain::Conversation::ResponseBuilderJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe '#perform' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :pending) }
    let(:mock_agent_runner_service) { instance_double(Captain::Assistant::AgentRunnerService) }
    let!(:responding_to_message) { create(:message, conversation: conversation, content: 'Hello', message_type: :incoming) }
    let(:v2_response_parts) { [{ 'text' => 'Hey, welcome to Captain V2', 'citation_indexes' => [] }] }

    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      allow(inbox).to receive(:captain_active?).and_return(true)
      allow(Captain::Assistant::AgentRunnerService).to receive(:new).and_return(mock_agent_runner_service)
      allow(mock_agent_runner_service).to receive(:generate_response).and_return({
                                                                                   'response_parts' => v2_response_parts,
                                                                                   'response' => 'Hey, welcome to Captain V2',
                                                                                   'reasoning' => 'A friendly greeting'
                                                                                 })
      allow(mock_agent_runner_service).to receive(:last_run_result).and_return(nil)
      allow(mock_agent_runner_service).to receive(:response_discarded?).and_return(false)
      allow(mock_agent_runner_service).to receive(:handoff_completed?).and_return(false)
    end

    context 'when captain_v2 is enabled' do
      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration').and_return(true)
      end

      context 'with message burst protection' do
        it 'passes the responding message id to the runner' do
          expect(Captain::Assistant::AgentRunnerService).to receive(:new).with(
            assistant: assistant,
            conversation: conversation,
            run_options: Captain::Assistant::AgentRunnerService::RunOptions.new(
              responding_to_message_id: responding_to_message.id
            )
          )

          described_class.perform_now(conversation, assistant, responding_to_message.id)
        end

        it 'discards a response when the runner sees a newer customer message' do
          allow(mock_agent_runner_service).to receive(:generate_response) do
            create(:message, conversation: conversation, content: 'New context', message_type: :incoming)
            { 'response' => 'Stale response', 'handoff_tool_called' => false }
          end
          allow(mock_agent_runner_service).to receive(:response_discarded?).and_return(true)

          described_class.perform_now(conversation, assistant, responding_to_message.id)

          expect(conversation.messages.outgoing.count).to eq(0)
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
        end

        it 'checks freshness itself after generation' do
          allow(mock_agent_runner_service).to receive(:generate_response) do
            create(:message, conversation: conversation, content: 'New context', message_type: :incoming)
            { 'response' => 'Stale response', 'handoff_tool_called' => false }
          end
          allow(mock_agent_runner_service).to receive(:response_discarded?).and_return(false)

          described_class.perform_now(conversation, assistant, responding_to_message.id)

          expect(conversation.messages.outgoing.count).to eq(0)
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
        end

        it 'does not emit a response completed event for a stale response' do
          allow(mock_agent_runner_service).to receive(:generate_response) do
            create(:message, conversation: conversation, content: 'New context', message_type: :incoming)
            { 'response' => 'Stale response', 'handoff_tool_called' => false }
          end

          expect(Captain::ConversationEvents).not_to receive(:response_completed)

          described_class.perform_now(conversation, assistant, responding_to_message.id)
        end

        it 'emits only the response failed event when generation raises after a newer message arrived' do
          allow(mock_agent_runner_service).to receive(:generate_response) do
            create(:message, conversation: conversation, content: 'New context', message_type: :incoming)
            raise StandardError, 'llm down'
          end

          expect(Captain::ConversationEvents).to receive(:response_failed)
            .with(conversation: conversation, assistant: assistant, reason: 'standard_error', at: kind_of(Time))
          expect(Captain::ConversationEvents).not_to receive(:handed_off)

          described_class.perform_now(conversation, assistant, responding_to_message.id)

          expect(conversation.messages.outgoing.count).to eq(0)
          expect(conversation.reload.status).to eq('pending')
        end

        it 'keeps the pending response fresh when an email auto reply arrives' do
          create(
            :message,
            conversation: conversation,
            message_type: :incoming,
            content_type: :incoming_email,
            content_attributes: { email: { auto_reply: true } }
          )

          described_class.perform_now(conversation, assistant, responding_to_message.id)

          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain V2')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(1)
        end
      end

      it 'passes message history with resolution markers to agent runner service' do
        same_second = Time.current.change(usec: 0)
        responding_to_message.update!(created_at: same_second, updated_at: same_second)
        create(
          :message,
          conversation: conversation,
          sender: assistant,
          content: 'Earlier answer [[1](https://help.example.com/private-from-model)]',
          message_type: :outgoing,
          additional_attributes: {
            Captain::Assistant::ResponseParts::MESSAGE_ATTRIBUTE_KEY => [
              { 'text' => 'Earlier answer', 'citation_indexes' => [1] }
            ]
          },
          created_at: same_second,
          updated_at: same_second
        )
        create(
          :message,
          conversation: conversation,
          message_type: :activity,
          content: 'Conversation was marked resolved by Alice',
          content_attributes: { activity: { type: 'conversation_status_changed', status: 'resolved' } },
          created_at: same_second,
          updated_at: same_second
        )
        create(:message, conversation: conversation, message_type: :activity, content: 'Assigned to agent', created_at: same_second,
                         updated_at: same_second)
        create(:message, conversation: conversation, content: 'Fresh question', message_type: :incoming, created_at: same_second,
                         updated_at: same_second)

        expected_messages = [
          { content: 'Hello', role: 'user' },
          { content: 'Earlier answer', role: 'assistant' },
          {
            content: Captain::Conversation::MessageHistoryBuilderService::RESOLUTION_MARKER,
            role: 'assistant'
          },
          { content: 'Fresh question', role: 'user' }
        ]

        expect(mock_agent_runner_service).to receive(:generate_response).with(
          message_history: expected_messages
        )

        described_class.perform_now(conversation, assistant)
      end

      it 'does not restore deleted Captain response parts into message history' do
        deleted_content = I18n.t('conversations.messages.deleted')
        create(
          :message,
          conversation: conversation,
          sender: assistant,
          content: deleted_content,
          content_attributes: { deleted: true },
          message_type: :outgoing,
          additional_attributes: {
            Captain::Assistant::ResponseParts::MESSAGE_ATTRIBUTE_KEY => [
              { 'text' => 'Sensitive deleted answer', 'citation_indexes' => [] }
            ]
          }
        )

        expect(mock_agent_runner_service).to receive(:generate_response).with(
          message_history: [
            { content: 'Hello', role: 'user' },
            { content: deleted_content, role: 'assistant' }
          ]
        )

        described_class.perform_now(conversation, assistant)
      end

      it 'generates and processes response' do
        described_class.perform_now(conversation, assistant)
        expect(conversation.messages.count).to eq(2)
        expect(conversation.messages.outgoing.count).to eq(1)
        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain V2')
        expect(
          conversation.messages.last.additional_attributes[Captain::Assistant::ResponseParts::MESSAGE_ATTRIBUTE_KEY]
        ).to eq(v2_response_parts)
      end

      it 'increments usage response' do
        described_class.perform_now(conversation, assistant)
        account.reload
        expect(account.usage_limits[:captain][:responses][:consumed]).to eq(1)
      end

      context 'with structured citations' do
        before do
          allow(Resolv).to receive(:getaddresses).and_return(['93.184.216.34'])

          first_document = create(:captain_document, assistant: assistant, external_link: 'https://help.example.com/password')
          second_document = create(:captain_document, assistant: assistant, external_link: 'https://help.example.com/email')
          run_result = Agents::RunResult.new(
            output: { 'response_parts' => v2_response_parts, 'reasoning' => 'Used the FAQ results' },
            context: {
              state: {
                Captain::Assistant::CITATION_SOURCES_STATE_KEY => {
                  1 => first_document.id,
                  2 => second_document.id
                }
              }
            }
          )
          allow(mock_agent_runner_service).to receive(:last_run_result).and_return(run_result)
          assistant.update!(config: assistant.config.merge('feature_citation' => true))
        end

        it 'does not render links when citations are disabled' do
          assistant.update!(config: assistant.config.merge('feature_citation' => false))
          v2_response_parts.first['citation_indexes'] = [1]

          described_class.perform_now(conversation, assistant)

          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain V2')
        end

        it 'renders one cited document from the trusted run mapping' do
          v2_response_parts.first['citation_indexes'] = [1]

          described_class.perform_now(conversation, assistant)

          expect(conversation.messages.outgoing.last.content).to eq(
            'Hey, welcome to Captain V2 [[1](https://help.example.com/password)]'
          )
          cited_document_id = mock_agent_runner_service.last_run_result.context[:state][Captain::Assistant::CITATION_SOURCES_STATE_KEY][1]
          expect(Captain::AgentSession.last.cited_document_ids).to eq([cited_document_id])
        end

        it 'encodes Markdown delimiters in citation URLs' do
          document = create(
            :captain_document,
            assistant: assistant,
            external_link: 'https://help.example.com/guides/reset_(new)'
          )
          citation_sources = mock_agent_runner_service.last_run_result.context[:state][Captain::Assistant::CITATION_SOURCES_STATE_KEY]
          citation_sources[3] = document.id
          v2_response_parts.first['citation_indexes'] = [3]

          described_class.perform_now(conversation, assistant)

          content = conversation.messages.outgoing.last.content
          expect(content).to eq('Hey, welcome to Captain V2 [[1](https://help.example.com/guides/reset_%28new%29)]')
          expect(ChatwootMarkdownRenderer.new(content).render_message.to_s).to include(
            '<a href="https://help.example.com/guides/reset_%28new%29">1</a>'
          )
        end

        it 'renders a citation after a closing code fence' do
          v2_response_parts.replace(
            [
              { 'text' => "```ruby\nputs 'hello'\n```", 'citation_indexes' => [1] },
              { 'text' => 'Continue with the next step.', 'citation_indexes' => [2] }
            ]
          )

          described_class.perform_now(conversation, assistant)

          content = conversation.messages.outgoing.last.content
          expect(content).to eq(
            "```ruby\nputs 'hello'\n```\n[[1](https://help.example.com/password)]\n\n" \
            'Continue with the next step. [[2](https://help.example.com/email)]'
          )

          rendered_content = ChatwootMarkdownRenderer.new(content).render_message.to_s
          expect(rendered_content).to include("</code></pre>\n<p>[<a href=\"https://help.example.com/password\">1</a>]</p>")
          expect(rendered_content).to include('<p>Continue with the next step.')
        end

        it 'preserves response part order and numbers trusted sources by first appearance' do
          v2_response_parts.replace(
            [
              { 'text' => 'Email changes are in settings.', 'citation_indexes' => [2] },
              { 'text' => 'Password resets use the reset link.', 'citation_indexes' => [1] }
            ]
          )

          described_class.perform_now(conversation, assistant)

          expect(conversation.messages.outgoing.last.content).to eq(
            "Email changes are in settings. [[1](https://help.example.com/email)]\n\n" \
            'Password resets use the reset link. [[2](https://help.example.com/password)]'
          )
        end

        it 'reuses a display number when a response cites the same source more than once' do
          v2_response_parts.replace(
            [
              { 'text' => 'Use the reset link.', 'citation_indexes' => [1, 1] },
              { 'text' => 'The same page has the next steps.', 'citation_indexes' => [1] }
            ]
          )

          described_class.perform_now(conversation, assistant)

          expect(conversation.messages.outgoing.last.content).to eq(
            "Use the reset link. [[1](https://help.example.com/password)]\n\n" \
            'The same page has the next steps. [[1](https://help.example.com/password)]'
          )
        end

        it 'ignores unknown indexes and non-numeric citation values' do
          v2_response_parts.first['citation_indexes'] = [99, 'https://model.example/source']

          described_class.perform_now(conversation, assistant)

          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain V2')
        end

        it 'renders a wrong but valid index only through its trusted source mapping' do
          v2_response_parts.first['citation_indexes'] = [2, 'https://model.example/source']

          described_class.perform_now(conversation, assistant)

          content = conversation.messages.outgoing.last.content
          expect(content).to eq('Hey, welcome to Captain V2 [[1](https://help.example.com/email)]')
          expect(content).not_to include('model.example')
        end

        it 'does not render mapped PDF or non-public sources' do
          pdf_document = create(
            :captain_document,
            assistant: assistant,
            external_link: 'https://storage.example.com/private-file.pdf?token=secret'
          )
          citation_sources = mock_agent_runner_service.last_run_result.context[:state][Captain::Assistant::CITATION_SOURCES_STATE_KEY]
          citation_sources[3] = pdf_document.id
          citation_sources[4] = 0
          v2_response_parts.first['citation_indexes'] = [3, 4]

          described_class.perform_now(conversation, assistant)

          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain V2')
        end

        it 'joins valid markdown parts and drops blank or invalid parts' do
          v2_response_parts.replace(
            [
              { 'text' => "  **Steps**\n\n- Open settings  ", 'citation_indexes' => [] },
              { 'text' => '   ', 'citation_indexes' => [1] },
              'invalid',
              { 'text' => 'Save the change.', 'citation_indexes' => ['1'] }
            ]
          )

          described_class.perform_now(conversation, assistant)

          message = conversation.messages.outgoing.last
          expect(message.content).to eq("**Steps**\n\n- Open settings\n\nSave the change.")
          expect(message.additional_attributes[Captain::Assistant::ResponseParts::MESSAGE_ATTRIBUTE_KEY]).to eq(
            [
              { 'text' => "**Steps**\n\n- Open settings", 'citation_indexes' => [] },
              { 'text' => 'Save the change.', 'citation_indexes' => [] }
            ]
          )
        end
      end

      it 'emits a response completed event' do
        expect(Captain::ConversationEvents).to receive(:response_completed)
          .with(conversation: conversation, assistant: assistant, message: kind_of(Message), at: kind_of(Time))

        described_class.perform_now(conversation, assistant)
      end

      it 'emits response failed and generation failure handoff events when the runner returns an error response' do
        allow(mock_agent_runner_service).to receive(:generate_response).and_return(
          { 'response' => 'conversation_handoff', 'reasoning' => 'Error occurred: llm down', 'error' => true,
            'error_reason' => 'standard_error', 'handoff_tool_called' => false }
        )

        expect(Captain::ConversationEvents).to receive(:response_failed)
          .with(conversation: conversation, assistant: assistant, reason: 'standard_error', at: kind_of(Time))
        expect(Captain::ConversationEvents).to receive(:handed_off)
          .with(conversation: conversation, assistant: assistant, source: 'generation_failure', reason_category: :tool_failure, at: kind_of(Time))

        described_class.perform_now(conversation, assistant)
      end

      it 'emits response failed and generation failure handoff events when generation raises' do
        allow(mock_agent_runner_service).to receive(:generate_response).and_raise(StandardError, 'llm down')

        expect(Captain::ConversationEvents).to receive(:response_failed)
          .with(conversation: conversation, assistant: assistant, reason: 'standard_error', at: kind_of(Time))
        expect(Captain::ConversationEvents).to receive(:handed_off)
          .with(conversation: conversation, assistant: assistant, source: 'generation_failure', reason_category: :tool_failure, at: kind_of(Time))

        described_class.perform_now(conversation, assistant)
      end
    end

    context 'when captain_v2 handoff tool fires during agent execution' do
      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration').and_return(true)
        allow(mock_agent_runner_service).to receive(:handoff_completed?).and_return(true)
      end

      it 'creates a public handoff message after the generated response is discarded' do
        allow(mock_agent_runner_service).to receive(:response_discarded?).and_return(true)
        allow(mock_agent_runner_service).to receive(:generate_response) do
          conversation.update!(status: :open)
          { 'response' => 'Let me connect you', 'handoff_tool_called' => true }
        end

        described_class.perform_now(conversation, assistant)

        public_messages = conversation.messages.outgoing.where(private: false)
        expect(public_messages.count).to eq(1)
        expect(public_messages.last.content).to eq(I18n.t('conversations.captain.handoff'))
      end

      it 'does not call bot_handoff! again when conversation is already open' do
        allow(mock_agent_runner_service).to receive(:generate_response) do
          conversation.update!(status: :open)
          { 'response' => 'Let me connect you', 'handoff_tool_called' => true }
        end

        expect(conversation).not_to receive(:bot_handoff!)

        described_class.perform_now(conversation, assistant)
      end

      it 'keeps a completed tool handoff when the runner also reports an error' do
        allow(mock_agent_runner_service).to receive(:generate_response) do
          conversation.update!(status: :open)
          { 'error' => true, 'error_reason' => 'standard_error', 'handoff_tool_called' => true }
        end

        expect(Captain::ConversationEvents).to receive(:response_failed)
          .with(conversation: conversation, assistant: assistant, reason: 'standard_error', at: kind_of(Time))
        expect(conversation).not_to receive(:bot_handoff!)

        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.outgoing.where(private: false).count).to eq(1)
      end

      it 'does not create a duplicate out of office message' do
        allow(mock_agent_runner_service).to receive(:generate_response) do
          conversation.update!(status: :open)
          { 'response' => 'Let me connect you', 'handoff_tool_called' => true }
        end

        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.template.count).to eq(0)
      end

      it 'preserves waiting_since when HandoffTool already called bot_handoff!' do
        original_waiting_since = 5.minutes.ago
        conversation.update!(waiting_since: original_waiting_since)

        allow(mock_agent_runner_service).to receive(:generate_response) do
          conversation.update!(status: :open, waiting_since: original_waiting_since)
          { 'response' => 'Let me connect you', 'handoff_tool_called' => true }
        end

        described_class.perform_now(conversation, assistant)

        expect(conversation.reload.waiting_since).to be_within(1.second).of(original_waiting_since)
      end

      it 'does not hand off when handoff_tool_called is false' do
        allow(mock_agent_runner_service).to receive(:handoff_completed?).and_return(false)
        allow(mock_agent_runner_service).to receive(:generate_response).and_return({
                                                                                     'response' => 'Hi! How can I help you?',
                                                                                     'handoff_tool_called' => false
                                                                                   })

        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.outgoing.count).to eq(1)
        expect(conversation.messages.last.content).to eq('Hi! How can I help you?')
        expect(conversation.reload.status).to eq('pending')
      end

      it 'hands off when HandoffTool fired but failed to commit' do
        allow(mock_agent_runner_service).to receive(:handoff_completed?).and_return(false)
        allow(mock_agent_runner_service).to receive(:generate_response).and_return({
                                                                                     'response' => 'I tried to hand off',
                                                                                     'handoff_tool_called' => true
                                                                                   })
        expect(Captain::ConversationEvents).to receive(:handed_off)
          .with(conversation: conversation, assistant: assistant, source: 'tool', reason_category: :tool_failure, at: kind_of(Time))

        described_class.perform_now(conversation, assistant)

        conversation.reload
        expect(conversation.status).to eq('open')
        public_messages = conversation.messages.outgoing.where(private: false)
        expect(public_messages.count).to eq(1)
        expect(public_messages.last.content).to eq(I18n.t('conversations.captain.handoff'))
      end
    end

    context 'when capturing assistant sessions' do
      let(:run_context) do
        {
          session_id: "#{account.id}_#{conversation.display_id}",
          current_agent: 'Assistant',
          turn_count: 1,
          conversation_history: [
            { role: :user, content: 'Hello' },
            { role: :assistant, content: 'Hey, welcome to Captain V2', agent_name: 'Assistant' }
          ],
          state: { cw_metadata: { faq_ids: [7, 9], document_ids: [3] } }
        }
      end
      let(:usage) do
        Agents::RunContext::Usage.new.tap do |u|
          u.input_tokens = 100
          u.output_tokens = 20
          u.total_tokens = 120
        end
      end
      let(:run_result) { Agents::RunResult.new(output: { 'response' => 'Hey, welcome to Captain V2' }, usage: usage, context: run_context) }

      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration').and_return(true)
        allow(mock_agent_runner_service).to receive(:last_run_result).and_return(run_result)
      end

      it 'creates a session for a delivered response' do
        described_class.perform_now(conversation, assistant)

        session = Captain::AgentSession.last
        expect(session).to have_attributes(
          account_id: account.id,
          assistant_id: assistant.id,
          subject_id: conversation.id,
          subject_type: 'Conversation',
          result_id: conversation.messages.outgoing.last.id,
          result_type: 'Message',
          llm_model: 'openai-gpt-5.2',
          credits_consumed: 1.0,
          faq_ids: [7, 9],
          cited_document_ids: [],
          document_ids: [3],
          scenario_ids: [],
          user_id: nil
        )
        expect(session).to be_session_assistant
        expect(session.run_context.first).to include('role' => 'user', 'content' => 'Hello')
      end

      it 'creates a zero-credit session when the handoff tool fired' do
        allow(mock_agent_runner_service).to receive(:handoff_completed?).and_return(true)
        allow(mock_agent_runner_service).to receive(:generate_response) do
          conversation.update!(status: :open)
          { 'response' => 'Let me connect you', 'handoff_tool_called' => true }
        end

        described_class.perform_now(conversation, assistant)

        session = Captain::AgentSession.last
        expect(session.credits_consumed).to eq(0.0)
        expect(session.result_id).to eq(conversation.messages.outgoing.where(private: false).last.id)
        expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
      end

      it 'attributes the handoff session to the private reason note when the tool recorded one' do
        allow(mock_agent_runner_service).to receive(:handoff_completed?).and_return(true)
        handoff_note = create(:message, conversation: conversation, account: account, message_type: :outgoing,
                                        private: true, sender: assistant, content: 'Needs a human')
        run_context[:state][:cw_metadata][:handoff_note_id] = handoff_note.id
        allow(mock_agent_runner_service).to receive(:generate_response) do
          conversation.update!(status: :open)
          { 'response' => 'Let me connect you', 'handoff_tool_called' => true }
        end

        described_class.perform_now(conversation, assistant)

        session = Captain::AgentSession.last
        expect(session.credits_consumed).to eq(0.0)
        expect(session.result_id).to eq(handoff_note.id)
      end

      it 'creates a zero-credit session when the handoff tool fired but failed to commit' do
        allow(mock_agent_runner_service).to receive(:generate_response).and_return({
                                                                                     'response' => 'I tried to hand off',
                                                                                     'handoff_tool_called' => true
                                                                                   })

        described_class.perform_now(conversation, assistant)

        session = Captain::AgentSession.last
        expect(session.credits_consumed).to eq(0.0)
        expect(session.result_id).to eq(conversation.messages.outgoing.where(private: false).last.id)
      end

      it 'still delivers the reply when session capture fails' do
        allow(Captain::AgentSession).to receive(:create!).and_raise(StandardError, 'capture failed')
        allow(ChatwootExceptionTracker).to receive(:new).and_call_original

        expect do
          described_class.perform_now(conversation, assistant)
        end.not_to raise_error

        expect(conversation.messages.outgoing.count).to eq(1)
        expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain V2')
        expect(conversation.reload.status).to eq('pending')
        expect(ChatwootExceptionTracker).to have_received(:new)
      end
    end
  end

  describe 'job configuration' do
    it 'keeps retry rules for attachment and provider errors' do
      expect(described_class).to respond_to(:retry_on)
      expect(described_class::MAX_MESSAGE_LENGTH).to eq(10_000)
    end
  end
end
