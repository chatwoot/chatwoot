require 'rails_helper'

RSpec.describe Captain::Conversation::ResponseBuilderJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe '#perform' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :pending) }
    let(:mock_llm_chat_service) { instance_double(Captain::Llm::AssistantChatService) }
    let(:mock_agent_runner_service) { instance_double(Captain::Assistant::AgentRunnerService) }
    let(:mock_action_classifier_service) { instance_double(Captain::Llm::AssistantActionClassifierService) }
    let(:mock_false_promise_service) { instance_double(Captain::Llm::AssistantFalsePromiseService) }
    let(:assistant_model) { Llm::Models.default_model_for('assistant') }
    let!(:responding_to_message) { create(:message, conversation: conversation, content: 'Hello', message_type: :incoming) }
    let(:v2_response_parts) { [{ 'text' => 'Hey, welcome to Captain V2', 'citation_indexes' => [] }] }

    before do
      allow(inbox).to receive(:captain_active?).and_return(true)
      allow(Captain::Llm::AssistantChatService).to receive(:new).and_return(mock_llm_chat_service)
      allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'Hey, welcome to Captain Specs' })
      allow(Captain::Assistant::AgentRunnerService).to receive(:new).and_return(mock_agent_runner_service)
      allow(mock_agent_runner_service).to receive(:generate_response).and_return({
                                                                                   'response_parts' => v2_response_parts,
                                                                                   'response' => 'Hey, welcome to Captain V2',
                                                                                   'reasoning' => 'A friendly greeting'
                                                                                 })
      allow(mock_agent_runner_service).to receive(:last_run_result).and_return(nil)
      allow(mock_agent_runner_service).to receive(:response_discarded?).and_return(false)
      allow(mock_agent_runner_service).to receive(:handoff_completed?).and_return(false)
      allow(Captain::Llm::AssistantActionClassifierService).to receive(:new).and_return(mock_action_classifier_service)
      allow(mock_action_classifier_service).to receive(:classify).and_return({ 'action' => 'continue' })
      allow(Captain::Llm::AssistantFalsePromiseService).to receive(:new).and_return(mock_false_promise_service)
      allow(mock_false_promise_service).to receive(:detect).and_return({ 'decision' => 'safe', 'reason' => 'safe_response' })
    end

    context 'when captain_v2 is disabled' do
      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)
      end

      it 'uses Captain::Llm::AssistantChatService' do
        expect(Captain::Llm::AssistantChatService).to receive(:new).with(assistant: assistant, conversation: conversation)
        expect(Captain::Assistant::AgentRunnerService).not_to receive(:new)

        described_class.perform_now(conversation, assistant)
        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain Specs')
      end

      it 'generates and processes response' do
        described_class.perform_now(conversation, assistant)
        expect(conversation.messages.count).to eq(2)
        expect(conversation.messages.outgoing.count).to eq(1)
        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain Specs')
      end

      it 'does not emit captain lifecycle events' do
        expect(Captain::ConversationEvents).not_to receive(:response_completed)

        described_class.perform_now(conversation, assistant)
      end

      it 'keeps the default message history limited to public chat messages' do
        create(
          :message,
          conversation: conversation,
          message_type: :activity,
          content: 'Conversation was marked resolved',
          content_attributes: { activity: { type: 'conversation_status_changed', status: 'resolved' } }
        )
        create(:message, conversation: conversation, content: 'Private note', message_type: :outgoing, private: true)

        expect(mock_llm_chat_service).to receive(:generate_response).with(
          message_history: [{ content: 'Hello', role: 'user' }]
        ).and_return({ 'response' => 'Hey, welcome to Captain Specs' })

        described_class.perform_now(conversation, assistant)
      end

      it 'increments usage response' do
        described_class.perform_now(conversation, assistant)
        account.reload
        expect(account.usage_limits[:captain][:responses][:consumed]).to eq(1)
      end

      it 'does not create a captain session' do
        expect do
          described_class.perform_now(conversation, assistant)
        end.not_to change(Captain::AgentSession, :count)
      end

      it 'does not run the action classifier when the classifier feature is disabled' do
        expect(Captain::Llm::AssistantActionClassifierService).not_to receive(:new)

        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain Specs')
      end

      it 'does not run the false promise harness when the account setting is disabled' do
        expect(Captain::Llm::AssistantFalsePromiseService).not_to receive(:new)

        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain Specs')
      end

      context 'when false promise harness is enabled in account settings' do
        before do
          account.update!(settings: account.settings.merge('captain_false_promise_harness_enabled' => true))
        end

        it 'sends the original response when the detector marks it safe' do
          expect(mock_false_promise_service).to receive(:detect).with(
            message_history: [{ content: 'Hello', role: 'user' }],
            assistant_response: 'Hey, welcome to Captain Specs'
          ).and_return({
                         'decision' => 'safe',
                         'reason' => 'safe_response',
                         'model' => assistant_model
                       })

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('pending')
          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain Specs')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(1)
        end

        it 'regenerates future-work promises through the V1 assistant chat service' do
          allow(mock_llm_chat_service).to receive(:generate_response)
            .and_return(
              { 'response' => 'Let me check the documentation and get back to you.' },
              { 'response' => 'Could you share the exact error message you see?' }
            )
          allow(mock_false_promise_service).to receive(:detect)
            .and_return(
              {
                'decision' => 'future_work_promise',
                'reason' => 'future_check_or_investigation',
                'model' => assistant_model
              },
              {
                'decision' => 'safe',
                'reason' => 'asks_user_to_check_or_provide_info',
                'model' => assistant_model
              }
            )

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('pending')
          expect(conversation.messages.outgoing.last.content).to eq('Could you share the exact error message you see?')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(1)
          expect(mock_llm_chat_service).to have_received(:generate_response).with(
            message_history: [{ content: 'Hello', role: 'user' }]
          )
          expect(mock_llm_chat_service).to have_received(:generate_response).with(
            message_history: [
              { content: 'Hello', role: 'user' },
              { role: 'assistant', content: 'Let me check the documentation and get back to you.' }
            ],
            additional_message: Captain::Conversation::V1FalsePromiseHandler::FUTURE_PROMISE_REPAIR_INSTRUCTION
          )
        end

        it 'hands off instead of sending the unsafe draft when repair generation fails' do
          allow(mock_llm_chat_service).to receive(:generate_response)
            .and_return({ 'response' => 'Let me check and get back to you.' })
          allow(mock_llm_chat_service).to receive(:generate_response)
            .with(
              message_history: [
                { content: 'Hello', role: 'user' },
                { role: 'assistant', content: 'Let me check and get back to you.' }
              ],
              additional_message: Captain::Conversation::V1FalsePromiseHandler::FUTURE_PROMISE_REPAIR_INSTRUCTION
            ).and_raise(StandardError, 'repair timeout')
          allow(mock_false_promise_service).to receive(:detect).and_return({
                                                                             'decision' => 'future_work_promise',
                                                                             'reason' => 'future_check_or_investigation',
                                                                             'model' => assistant_model
                                                                           })

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('open')
          expect(conversation.messages.outgoing.last.content).to eq(I18n.t('conversations.captain.handoff'))
          expect(conversation.messages.outgoing.pluck(:content)).not_to include('Let me check and get back to you.')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
        end

        it 'hands off instead of sending an unverified repair when repair verification is inconclusive' do
          allow(mock_llm_chat_service).to receive(:generate_response)
            .and_return(
              { 'response' => 'Let me check and get back to you.' },
              { 'response' => 'Could you share the exact error message you see?' }
            )
          allow(mock_false_promise_service).to receive(:detect)
            .and_return(
              {
                'decision' => 'future_work_promise',
                'reason' => 'future_check_or_investigation',
                'model' => assistant_model
              },
              {
                'decision' => nil,
                'reason' => nil,
                'error' => 'verification timeout',
                'model' => assistant_model
              }
            )

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('open')
          expect(conversation.messages.outgoing.last.content).to eq(I18n.t('conversations.captain.handoff'))
          expect(conversation.messages.outgoing.pluck(:content)).not_to include('Could you share the exact error message you see?')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
        end

        it 'hands off when the regenerated response still contains a future-work promise' do
          allow(mock_llm_chat_service).to receive(:generate_response)
            .and_return(
              { 'response' => 'Let me check and get back to you.' },
              { 'response' => 'I will monitor this and update you later.' }
            )
          allow(mock_false_promise_service).to receive(:detect).and_return({
                                                                             'decision' => 'future_work_promise',
                                                                             'reason' => 'future_check_or_investigation',
                                                                             'model' => assistant_model
                                                                           })

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('open')
          expect(conversation.messages.outgoing.last.content).to eq(I18n.t('conversations.captain.handoff'))
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
        end

        it 'skips the false promise harness when the action classifier already requested handoff' do
          allow(account).to receive(:feature_enabled?).and_return(false)
          allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)
          allow(account).to receive(:feature_enabled?).with('captain_v1_action_classifier').and_return(true)
          allow(mock_action_classifier_service).to receive(:classify).and_return({
                                                                                   'action' => 'handoff',
                                                                                   'action_reason' => 'explicit_human_request',
                                                                                   'model' => 'gpt-4.1'
                                                                                 })

          expect(Captain::Llm::AssistantFalsePromiseService).not_to receive(:new)

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('open')
          expect(conversation.messages.outgoing.last.content).to eq(I18n.t('conversations.captain.handoff'))
        end
      end

      context 'when V1 action classifier is enabled' do
        before do
          allow(account).to receive(:feature_enabled?).and_return(false)
          allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)
          allow(account).to receive(:feature_enabled?).with('captain_v1_action_classifier').and_return(true)
        end

        it 'keeps the conversation pending when the classifier returns continue' do
          expect(Captain::Llm::AssistantActionClassifierService).to receive(:new).with(
            assistant: assistant,
            conversation: conversation
          ).and_return(mock_action_classifier_service)
          expect(mock_action_classifier_service).to receive(:classify).with(
            message_history: [{ content: 'Hello', role: 'user' }],
            assistant_response: 'Hey, welcome to Captain Specs'
          ).and_return({
                         'action' => 'continue',
                         'action_reason' => 'general_product_question',
                         'model' => 'gpt-4.1'
                       })

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('pending')
          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain Specs')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(1)
        end

        it 'hands off without incrementing response usage when the classifier returns handoff' do
          allow(mock_action_classifier_service).to receive(:classify).and_return({
                                                                                   'action' => 'handoff',
                                                                                   'action_reason' => 'explicit_human_request',
                                                                                   'model' => 'gpt-4.1'
                                                                                 })

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('open')
          expect(conversation.messages.outgoing.last.content).to eq(I18n.t('conversations.captain.handoff'))
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
        end

        it 'skips the classifier when the legacy handoff token is returned' do
          allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'conversation_handoff' })
          expect(Captain::Llm::AssistantActionClassifierService).not_to receive(:new)

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('open')
          expect(conversation.messages.outgoing.last.content).to eq(I18n.t('conversations.captain.handoff'))
        end

        it 'falls back to the assistant response when the classifier fails' do
          error = StandardError.new('classifier unavailable')
          allow(mock_action_classifier_service).to receive(:classify).and_raise(error)
          allow(ChatwootExceptionTracker).to receive(:new).and_call_original

          described_class.perform_now(conversation, assistant)

          expect(ChatwootExceptionTracker).to have_received(:new).with(error, account: account)
          expect(conversation.reload.status).to eq('pending')
          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain Specs')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(1)
        end

        it 'falls back to the assistant response when the classifier returns an invalid action' do
          allow(mock_action_classifier_service).to receive(:classify).and_return({
                                                                                   'action' => nil,
                                                                                   'error' => 'invalid_classifier_response'
                                                                                 })

          described_class.perform_now(conversation, assistant)

          expect(conversation.reload.status).to eq('pending')
          expect(conversation.messages.outgoing.last.content).to eq('Hey, welcome to Captain Specs')
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(1)
        end

        it 'skips the classifier when the conversation is no longer pending after response generation' do
          allow(mock_llm_chat_service).to receive(:generate_response) do
            conversation.open!
            { 'response' => 'Hey, welcome to Captain Specs' }
          end

          expect(Captain::Llm::AssistantActionClassifierService).not_to receive(:new)

          described_class.perform_now(conversation, assistant)

          expect(conversation.messages.outgoing.count).to eq(0)
          expect(account.reload.usage_limits[:captain][:responses][:consumed]).to eq(0)
        end
      end

      it 'does not send a response when the conversation is no longer pending' do
        conversation.open!

        expect(mock_llm_chat_service).not_to receive(:generate_response)
        expect do
          described_class.perform_now(conversation, assistant)
        end.not_to(change { conversation.messages.outgoing.count })
      end
    end

    context 'when captain_v2 is enabled' do
      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)
      end

      context 'with message burst protection' do
        it 'passes the responding message id to the runner' do
          expect(Captain::Assistant::AgentRunnerService).to receive(:new).with(
            assistant: assistant,
            conversation: conversation,
            responding_to_message_id: responding_to_message.id
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
        allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)
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

      it 'falls back to a full V1 handoff when HandoffTool fired but failed to commit' do
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
        allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)
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

    # Regression (PR #13417): wrapping create_handoff_message and bot_handoff! in the
    # same transaction defers the message's after_create_commit until commit, at which
    # point it clears waiting_since (bot_response). The handoff path must stay outside
    # the transaction so the callback fires before bot_handoff! sets waiting_since.
    context 'when handoff is requested' do
      let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :pending) }
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)
        allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'conversation_handoff' })
      end

      it 'sets waiting_since to approximately the handoff time' do
        # Don't use freeze_time here: we need a real gap between the seeded waiting_since
        # and Time.current, otherwise "preserved" and "reset" both look identical.
        conversation.update!(waiting_since: 10.minutes.ago)

        described_class.perform_now(conversation, assistant)

        conversation.reload
        expect(conversation.status).to eq('open')
        expect(conversation.waiting_since).to be_within(5.seconds).of(Time.current)
      end

      it 'preserves waiting_since so a human reply consumes it for reply_time tracking' do
        described_class.perform_now(conversation, assistant)

        conversation.reload
        expect(conversation.waiting_since).to be_present

        # A human reply clears waiting_since (consumed by dispatch_create_events
        # to emit FIRST_REPLY_CREATED or REPLY_CREATED for reply_time tracking).
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: agent, account: account, inbox: inbox)
        expect(conversation.reload.waiting_since).to be_nil
      end
    end

    context 'when message contains an image' do
      let(:message_with_image) { create(:message, conversation: conversation, message_type: :incoming, content: 'Can you help with this error?') }
      let(:image_attachment) { message_with_image.attachments.create!(account: account, file_type: :image, external_url: 'https://example.com/error.jpg') }

      before do
        image_attachment
      end

      it 'includes image URL directly in the message content for OpenAI vision analysis' do
        # Expect the generate_response to receive multimodal content with image URL
        expect(mock_llm_chat_service).to receive(:generate_response) do |**kwargs|
          history = kwargs[:message_history]
          last_entry = history.last
          expect(last_entry[:content]).to be_an(Array)
          expect(last_entry[:content].any? { |part| part[:type] == 'text' && part[:text] == 'Can you help with this error?' }).to be true
          expect(last_entry[:content].any? do |part|
            part[:type] == 'image_url' && part[:image_url][:url] == 'https://example.com/error.jpg'
          end).to be true
          { 'response' => 'I can see the error in your image. It appears to be a database connection issue.' }
        end

        described_class.perform_now(conversation, assistant)
      end
    end
  end

  describe 'retry mechanisms for image processing' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :pending) }
    let(:mock_llm_chat_service) { instance_double(Captain::Llm::AssistantChatService) }
    let(:mock_message_builder) { instance_double(Captain::OpenAiMessageBuilderService) }

    before do
      create(:message, conversation: conversation, content: 'Hello with image', message_type: :incoming)
      allow(Captain::Llm::AssistantChatService).to receive(:new).and_return(mock_llm_chat_service)
      allow(Captain::OpenAiMessageBuilderService).to receive(:new).with(message: anything).and_return(mock_message_builder)
      allow(mock_message_builder).to receive(:generate_content).and_return('Hello with image')
      allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'Test response' })
    end

    context 'when ActiveStorage::FileNotFoundError occurs' do
      it 'handles file errors and triggers handoff' do
        allow(mock_message_builder).to receive(:generate_content)
          .and_raise(ActiveStorage::FileNotFoundError, 'Image file not found')

        # For retryable errors, the job should handle them and proceed with handoff
        described_class.perform_now(conversation, assistant)

        # Verify handoff occurred due to repeated failures
        expect(conversation.reload.status).to eq('open')
      end

      it 'succeeds when no error occurs' do
        # Don't raise any error, should succeed normally
        allow(mock_message_builder).to receive(:generate_content)
          .and_return('Image content processed successfully')

        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.outgoing.count).to eq(1)
        expect(conversation.messages.outgoing.last.content).to eq('Test response')
      end
    end

    context 'when Faraday::BadRequestError occurs' do
      it 'handles API errors and triggers handoff' do
        allow(mock_llm_chat_service).to receive(:generate_response)
          .and_raise(Faraday::BadRequestError, 'Bad request to image service')
        allow(Rails.logger).to receive(:info).and_call_original

        described_class.perform_now(conversation, assistant)
        expect(conversation.reload.status).to eq('open')
        expect(Rails.logger).to have_received(:info).with(include('source=error reason=faraday_bad_request_error'))
      end

      it 'succeeds when no error occurs' do
        # Don't raise any error, should succeed normally
        allow(mock_llm_chat_service).to receive(:generate_response)
          .and_return({ 'response' => 'Response after retry' })

        described_class.perform_now(conversation, assistant)

        expect(conversation.messages.outgoing.last.content).to eq('Response after retry')
      end
    end

    context 'when image processing fails permanently' do
      before do
        allow(mock_message_builder).to receive(:generate_content)
          .and_raise(ActiveStorage::FileNotFoundError, 'Image permanently unavailable')
      end

      it 'triggers handoff after max retries' do
        # Since perform_now re-raises retryable errors, simulate the final failure after retries
        allow(mock_message_builder).to receive(:generate_content)
          .and_raise(StandardError, 'Max retries exceeded')

        expect(ChatwootExceptionTracker).to receive(:new).and_call_original

        described_class.perform_now(conversation, assistant)

        expect(conversation.reload.status).to eq('open')
      end
    end

    context 'when non-retryable error occurs' do
      let(:standard_error) { StandardError.new('Generic error') }

      before do
        allow(mock_llm_chat_service).to receive(:generate_response).and_raise(standard_error)
      end

      it 'handles error and triggers handoff' do
        expect(ChatwootExceptionTracker).to receive(:new)
          .with(standard_error, account: account)
          .and_call_original

        described_class.perform_now(conversation, assistant)

        expect(conversation.reload.status).to eq('open')
      end

      it 'ensures Current.executed_by is reset' do
        expect(Current).to receive(:executed_by=).with(assistant)
        expect(Current).to receive(:executed_by=).with(nil)

        described_class.perform_now(conversation, assistant)
      end
    end
  end

  describe 'job configuration' do
    it 'has retry_on configuration for retryable errors' do
      expect(described_class).to respond_to(:retry_on)
    end

    it 'defines MAX_MESSAGE_LENGTH constant' do
      expect(described_class::MAX_MESSAGE_LENGTH).to eq(10_000)
    end
  end

  describe 'out of office message after handoff' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :pending) }
    let(:mock_llm_chat_service) { instance_double(Captain::Llm::AssistantChatService) }

    before do
      create(:message, conversation: conversation, content: 'Hello', message_type: :incoming)
      allow(Captain::Llm::AssistantChatService).to receive(:new).and_return(mock_llm_chat_service)
      allow(account).to receive(:feature_enabled?).and_return(false)
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)
    end

    context 'when handoff occurs outside business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed. Please leave your email.'
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )
        allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'conversation_handoff' })
      end

      it 'sends out of office message after handoff' do
        expect do
          described_class.perform_now(conversation, assistant)
        end.to change { conversation.messages.template.count }.by(1)

        expect(conversation.reload.status).to eq('open')
        ooo_message = conversation.messages.template.last
        expect(ooo_message.content).to eq('We are currently closed. Please leave your email.')
      end
    end

    context 'when handoff occurs within business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed.'
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          open_all_day: true,
          closed_all_day: false
        )
        allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'conversation_handoff' })
      end

      it 'does not send out of office message after handoff' do
        expect do
          described_class.perform_now(conversation, assistant)
        end.not_to(change { conversation.messages.template.count })

        expect(conversation.reload.status).to eq('open')
      end
    end

    context 'when handoff occurs due to error outside business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed.'
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )
        allow(mock_llm_chat_service).to receive(:generate_response).and_raise(StandardError, 'API error')
      end

      it 'sends out of office message after error-triggered handoff' do
        expect do
          described_class.perform_now(conversation, assistant)
        end.to change { conversation.messages.template.count }.by(1)

        expect(conversation.reload.status).to eq('open')
        ooo_message = conversation.messages.template.last
        expect(ooo_message.content).to eq('We are currently closed.')
      end
    end

    context 'when no out of office message is configured' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: nil
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )
        allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'conversation_handoff' })
      end

      it 'does not send out of office message' do
        expect do
          described_class.perform_now(conversation, assistant)
        end.not_to(change { conversation.messages.template.count })
      end
    end
  end
end
