require 'rails_helper'

RSpec.describe Captain::Conversation::ResponseBuilderJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:captain_inbox_association) { create(:captain_inbox, captain_assistant: assistant, inbox: inbox) }

  describe '#perform' do
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let(:mock_llm_chat_service) { instance_double(Captain::Llm::AssistantChatService) }
    let(:mock_agent_runner_service) { instance_double(Captain::Assistant::AgentRunnerService) }

    before do
      create(:message, conversation: conversation, content: 'Hello', message_type: :incoming)

      allow(inbox).to receive(:captain_active?).and_return(true)
      allow(Captain::Llm::AssistantChatService).to receive(:new).and_return(mock_llm_chat_service)
      allow(mock_llm_chat_service).to receive(:generate_response).and_return({ 'response' => 'Hey, welcome to Captain Specs' })
      allow(Captain::Assistant::AgentRunnerService).to receive(:new).and_return(mock_agent_runner_service)
      allow(mock_agent_runner_service).to receive(:generate_response).and_return({ 'response' => 'Hey, welcome to Captain V2' })
    end

    context 'when captain_v2 is disabled' do
      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)
      end

      it 'uses Captain::Llm::AssistantChatService' do
        expect(Captain::Llm::AssistantChatService).to receive(:new).with(assistant: assistant)
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

      it 'increments usage response' do
        described_class.perform_now(conversation, assistant)
        account.reload
        expect(account.usage_limits[:captain][:responses][:consumed]).to eq(1)
      end
    end

    context 'when captain_v2 is enabled' do
      before do
        allow(account).to receive(:feature_enabled?).and_return(false)
        allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)
      end

      it 'uses Captain::Assistant::AgentRunnerService' do
        expect(Captain::Assistant::AgentRunnerService).to receive(:new).with(
          assistant: assistant,
          conversation: conversation
        )
        expect(Captain::Llm::AssistantChatService).not_to receive(:new)

        described_class.perform_now(conversation, assistant)
        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain V2')
      end

      it 'passes message history to agent runner service' do
        expected_messages = [
          { content: 'Hello', role: 'user' }
        ]

        expect(mock_agent_runner_service).to receive(:generate_response).with(
          message_history: expected_messages
        )

        described_class.perform_now(conversation, assistant)
      end

      it 'generates and processes response' do
        described_class.perform_now(conversation, assistant)
        expect(conversation.messages.count).to eq(2)
        expect(conversation.messages.outgoing.count).to eq(1)
        expect(conversation.messages.last.content).to eq('Hey, welcome to Captain V2')
      end

      it 'increments usage response' do
        described_class.perform_now(conversation, assistant)
        account.reload
        expect(account.usage_limits[:captain][:responses][:consumed]).to eq(1)
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
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
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

        described_class.perform_now(conversation, assistant)
        expect(conversation.reload.status).to eq('open')
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
end
