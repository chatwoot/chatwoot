require 'rails_helper'

RSpec.describe Captain::Tools::HandoffTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, status: :pending) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Hand off the conversation to a human agent when unable to assist further')
    end
  end

  describe '#params_schema' do
    it 'constrains the reason category to the supported values and keeps the reason optional' do
      schema = tool.params_schema

      expect(schema['properties']['reason']['type']).to eq('string')
      expect(schema['properties']['reason_category']['enum']).to eq(described_class::REASON_CATEGORIES)
      expect(schema['required']).to eq(['reason_category'])
    end

    it 'uses only reason categories supported by conversation outcomes' do
      expect(ConversationOutcome::HANDOFF_REASON_CATEGORIES).to include(*described_class::REASON_CATEGORIES)
    end

    it 'survives Agents::ToolWrapper reading the class params at wrap time' do
      described_class.params

      expect(described_class.new(assistant).params_schema['properties'].keys).to contain_exactly('reason', 'reason_category')
    end
  end

  describe '#perform' do
    context 'when conversation exists' do
      context 'when Captain is responding to a customer message' do
        let(:responding_to_message) do
          create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
        end
        let(:tool_context) do
          Struct.new(:state).new({ conversation: { id: conversation.id }, responding_to_message_id: responding_to_message.id })
        end

        before do
          account.enable_features!(:captain_integration_v2)
          responding_to_message
        end

        it 'hands off when no newer customer message has arrived' do
          found_conversation = Conversation.find(conversation.id)
          scoped_conversations = Conversation.where(account_id: assistant.account_id)
          allow(Conversation).to receive(:where).with(account_id: assistant.account_id).and_return(scoped_conversations)
          allow(scoped_conversations).to receive(:find_by).with(id: conversation.id).and_return(found_conversation)
          expect(found_conversation).to receive(:with_lock).and_call_original

          expect do
            result = tool.perform(tool_context, reason: 'Customer needs specialized support')
            expect(result).to include('Conversation handed off')
          end.to change(Message, :count).by(1)
          expect(tool_context.state[:captain_v2_handoff_tool_completed]).to be true
        end

        it 'dispatches the handoff event after leaving the lock transaction' do
          found_conversation = Conversation.find(conversation.id)
          scoped_conversations = Conversation.where(account_id: assistant.account_id)
          allow(Conversation).to receive(:where).with(account_id: assistant.account_id).and_return(scoped_conversations)
          allow(scoped_conversations).to receive(:find_by).with(id: conversation.id).and_return(found_conversation)
          open_transactions_before_handoff = ActiveRecord::Base.connection.open_transactions

          expect(found_conversation).to receive(:dispatch_bot_handoff_event) do
            expect(ActiveRecord::Base.connection.open_transactions).to eq(open_transactions_before_handoff)
          end

          tool.perform(tool_context, reason: 'Customer needs specialized support')
        end

        it 'notifies inbox members after the committed handoff' do
          create(:inbox_member, user: user, inbox: inbox)
          notification_setting = user.notification_settings.find_by!(account: account)
          notification_setting.selected_email_flags = [:email_conversation_creation]
          notification_setting.selected_push_flags = []
          notification_setting.save!

          perform_enqueued_jobs do
            tool.perform(tool_context, reason: 'Customer needs specialized support')
          end

          expect(user.notifications.find_by(primary_actor: conversation, notification_type: :conversation_creation)).to be_present
        end

        it 'skips the handoff when a newer message has arrived' do
          conversation.update!(status: :pending)
          create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)

          expect do
            result = tool.perform(tool_context, reason: 'Customer needs specialized support')
            expect(result).to eq('Handoff skipped because a newer customer message arrived')
          end.not_to change(Message, :count)
          expect(conversation.reload.status).to eq('pending')
        end

        it 'emits a captain handoff event with the tool source after the locked handoff completes' do
          expect(Captain::ConversationEvents).to receive(:handed_off)
            .with(conversation: conversation, assistant: assistant, source: 'tool', reason_category: 'customer_request', at: kind_of(Time))

          tool.perform(tool_context, reason: 'Customer needs specialized support', reason_category: 'customer_request')
        end

        it 'emits an unclassified handoff when the model supplies an unknown reason category' do
          expect(Captain::ConversationEvents).to receive(:handed_off)
            .with(conversation: conversation, assistant: assistant, source: 'tool', reason_category: nil, at: kind_of(Time))

          tool.perform(tool_context, reason: 'Customer needs specialized support', reason_category: 'hallucinated_category')
        end

        it 'does not emit a captain handoff event when the handoff is skipped as stale' do
          create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)

          expect(Captain::ConversationEvents).not_to receive(:handed_off)

          tool.perform(tool_context, reason: 'Customer needs specialized support')
        end
      end

      context 'with Captain V1' do
        let(:tool_context) do
          Struct.new(:state).new({ conversation: { id: conversation.id }, responding_to_message_id: responding_to_message.id })
        end
        let(:responding_to_message) do
          create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
        end

        it 'uses the legacy handoff without a lock or stale-message guard' do
          responding_to_message
          create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
          found_conversation = Conversation.find(conversation.id)
          scoped_conversations = Conversation.where(account_id: assistant.account_id)
          allow(Conversation).to receive(:where).with(account_id: assistant.account_id).and_return(scoped_conversations)
          allow(scoped_conversations).to receive(:find_by).with(id: conversation.id).and_return(found_conversation)
          expect(found_conversation).not_to receive(:with_lock)

          result = tool.perform(tool_context, reason: 'Customer needs specialized support')

          expect(result).to include('Conversation handed off')
          expect(conversation.reload.status).to eq('open')
          expect(tool_context.state).not_to have_key(:captain_v2_handoff_tool_completed)
        end
      end

      context 'with reason provided' do
        it 'creates a private note with reason and hands off conversation' do
          reason = 'Customer needs specialized support'

          expect do
            result = tool.perform(tool_context, reason: reason)
            expect(result).to eq("Conversation handed off to human support team (Reason: #{reason})")
          end.to change(Message, :count).by(1)
        end

        it 'creates message with correct attributes' do
          reason = 'Customer needs specialized support'
          tool.perform(tool_context, reason: reason)

          created_message = Message.last
          expect(created_message.content).to eq(reason)
          expect(created_message.message_type).to eq('outgoing')
          expect(created_message.private).to be true
          expect(created_message.sender).to eq(assistant)
          expect(created_message.account).to eq(account)
          expect(created_message.inbox).to eq(inbox)
          expect(created_message.conversation).to eq(conversation)
        end

        it 'triggers bot handoff on conversation' do
          # The tool finds the conversation by ID, so we need to mock the found conversation
          found_conversation = Conversation.find(conversation.id)
          scoped_conversations = Conversation.where(account_id: assistant.account_id)
          allow(Conversation).to receive(:where).with(account_id: assistant.account_id).and_return(scoped_conversations)
          allow(scoped_conversations).to receive(:find_by).with(id: conversation.id).and_return(found_conversation)
          expect(found_conversation).to receive(:bot_handoff!)

          tool.perform(tool_context, reason: 'Test reason')
        end

        it 'emits a captain handoff event with the tool source and reason category' do
          expect(Captain::ConversationEvents).to receive(:handed_off)
            .with(conversation: conversation, assistant: assistant, source: 'tool', reason_category: 'unsupported_request', at: kind_of(Time))

          tool.perform(tool_context, reason: 'Test reason', reason_category: 'unsupported_request')
        end

        it 'records the handoff on an existing V2 outcome' do
          account.enable_features!('captain_integration_v2')
          create(
            :conversation_outcome,
            account: account,
            assistant: assistant,
            conversation: conversation,
            inbox: inbox
          )

          tool.perform(
            tool_context,
            reason: 'Customer needs specialized support',
            reason_category: 'unsupported_request'
          )

          expect(ConversationOutcome.last).to have_attributes(
            handoff_reason_category: 'unsupported_request',
            handoff_at: be_present
          )
        end

        it 'creates a conversation_bot_handoff reporting event' do
          create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
          Current.executed_by = assistant

          perform_enqueued_jobs do
            tool.perform(tool_context, reason: 'Customer needs specialized support')
          end

          reporting_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'conversation_bot_handoff')
          expect(reporting_event).to be_present
        ensure
          Current.reset
        end

        it 'logs tool usage with reason' do
          reason = 'Customer needs help'
          expect(tool).to receive(:log_tool_usage).with(
            'tool_handoff',
            { conversation_id: conversation.id, reason: reason }
          )

          tool.perform(tool_context, reason: reason)
        end

        it 'records the handoff note id in the run state for session capture' do
          tool.perform(tool_context, reason: 'Customer needs specialized support')

          expect(tool_context.state[:cw_metadata][:handoff_note_id]).to eq(Message.last.id)
        end
      end

      context 'without reason provided' do
        it 'creates a private note with nil content and hands off conversation' do
          expect do
            result = tool.perform(tool_context)
            expect(result).to eq('Conversation handed off to human support team')
          end.to change(Message, :count).by(1)

          created_message = Message.last
          expect(created_message.content).to be_nil
        end

        it 'logs tool usage with default reason' do
          expect(tool).to receive(:log_tool_usage).with(
            'tool_handoff',
            { conversation_id: conversation.id, reason: 'Agent requested handoff' }
          )

          tool.perform(tool_context)
        end

        it 'does not record a handoff note id since the empty note never renders' do
          tool.perform(tool_context)

          expect(tool_context.state[:cw_metadata]).to be_nil
        end
      end

      context 'when handoff fails' do
        before do
          # Mock the conversation lookup and handoff failure
          found_conversation = Conversation.find(conversation.id)
          scoped_conversations = Conversation.where(account_id: assistant.account_id)
          allow(Conversation).to receive(:where).with(account_id: assistant.account_id).and_return(scoped_conversations)
          allow(scoped_conversations).to receive(:find_by).with(id: conversation.id).and_return(found_conversation)
          allow(found_conversation).to receive(:bot_handoff!).and_raise(StandardError, 'Handoff error')

          exception_tracker = instance_double(ChatwootExceptionTracker)
          allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
          allow(exception_tracker).to receive(:capture_exception)
        end

        it 'returns error message' do
          result = tool.perform(tool_context, reason: 'Test')
          expect(result).to eq('Failed to handoff conversation')
        end

        it 'captures exception' do
          exception_tracker = instance_double(ChatwootExceptionTracker)
          expect(ChatwootExceptionTracker).to receive(:new).with(instance_of(StandardError)).and_return(exception_tracker)
          expect(exception_tracker).to receive(:capture_exception)

          tool.perform(tool_context, reason: 'Test')
        end
      end
    end

    context 'when conversation does not exist' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Conversation not found')
      end

      it 'does not create a message' do
        expect do
          tool.perform(tool_context, reason: 'Test')
        end.not_to change(Message, :count)
      end
    end

    context 'when conversation state is missing' do
      let(:tool_context) { Struct.new(:state).new({}) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Conversation not found')
      end
    end

    context 'when conversation id is nil' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Conversation not found')
      end
    end
  end

  describe '#active?' do
    it 'returns true for public tools' do
      expect(tool.active?).to be true
    end
  end

  describe 'out of office message after handoff' do
    context 'when outside business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed. Please leave your email.'
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          closed_all_day: true,
          open_all_day: false
        )
      end

      it 'sends out of office message after handoff' do
        expect do
          tool.perform(tool_context, reason: 'Customer needs help')
        end.to change { conversation.messages.template.count }.by(1)

        ooo_message = conversation.messages.template.last
        expect(ooo_message.content).to eq('We are currently closed. Please leave your email.')
      end
    end

    context 'when within business hours' do
      before do
        inbox.update!(
          working_hours_enabled: true,
          out_of_office_message: 'We are currently closed.'
        )
        inbox.working_hours.find_by(day_of_week: Time.current.in_time_zone(inbox.timezone).wday).update!(
          open_all_day: true,
          closed_all_day: false
        )
      end

      it 'does not send out of office message after handoff' do
        expect do
          tool.perform(tool_context, reason: 'Customer needs help')
        end.not_to(change { conversation.messages.template.count })
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
      end

      it 'does not send out of office message' do
        expect do
          tool.perform(tool_context, reason: 'Customer needs help')
        end.not_to(change { conversation.messages.template.count })
      end
    end
  end
end
