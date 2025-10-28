require 'rails_helper'

RSpec.describe Captain::Assistant::ConversationSummaryService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:service) { described_class.new(conversation: conversation) }
  let(:agent) { instance_double(Agents::Agent) }
  let(:runner) { instance_double(Agents::Runner) }
  let(:result) do
    instance_double(Agents::RunResult,
                    output: {
                      'customer_intent' => 'Customer wants to reset their password',
                      'conversation_summary' => 'The customer contacted support to reset their password. ' \
                                                'Agent provided instructions and confirmed the reset was successful.',
                      'action_items' => ['Send password reset email', 'Verify account security'],
                      'follow_up_items' => ['Check if customer needs additional security settings']
                    },
                    error: nil)
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4o-mini')
    create(:message, conversation: conversation, message_type: :incoming, content: 'I need to reset my password')
    create(:message, conversation: conversation, message_type: :outgoing, content: 'I can help you with that')
    allow(Agents::Agent).to receive(:new).and_return(agent)
    allow(Agents::Runner).to receive(:with_agents).and_return(runner)
    allow(runner).to receive(:run).with(anything, context: anything).and_return(result)
    allow(Captain::PromptRenderer).to receive(:render).and_return('summary prompt')
  end

  describe '#initialize' do
    it 'initializes with conversation' do
      expect(service.instance_variable_get(:@conversation)).to eq(conversation)
    end

    it 'formats conversation messages as text' do
      text = service.instance_variable_get(:@text)
      expect(text).to include('I need to reset my password')
      expect(text).to include('I can help you with that')
    end
  end

  describe '#execute' do
    context 'when successful' do
      it 'renders the summary prompt' do
        expect(Captain::PromptRenderer).to receive(:render).with('summary', {})
        service.execute
      end

      it 'builds agent with correct parameters' do
        expect(Agents::Agent).to receive(:new).with(
          name: 'ConversationSummarizer',
          instructions: 'summary prompt',
          model: 'gpt-4o-mini',
          response_schema: service.send(:response_schema)
        )
        service.execute
      end

      it 'returns success response with structured data' do
        response = service.execute
        expect(response[:success]).to be true
        expect(response[:structured_data][:customer_intent]).to eq('Customer wants to reset their password')
        expect(response[:structured_data][:conversation_summary]).to include('contacted support')
        expect(response[:structured_data][:action_items]).to include('Send password reset email')
        expect(response[:structured_data][:follow_up_items]).to include('Check if customer needs additional security settings')
      end

      it 'includes markdown formatted summary' do
        response = service.execute
        expect(response[:summary]).to include('**Customer Intent**')
        expect(response[:summary]).to include('**Conversation Summary**')
        expect(response[:summary]).to include('**Action Items**')
        expect(response[:summary]).to include('**Follow-up Items**')
      end
    end

    context 'when agent returns an error' do
      let(:result) { instance_double(Agents::RunResult, output: { error: 'Model error' }, error: nil) }

      it 'returns error response' do
        response = service.execute
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Model error')
      end
    end

    context 'when exception is raised' do
      before do
        allow(runner).to receive(:run).with(anything, context: anything).and_raise(StandardError.new('API timeout'))
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/ConversationSummaryService error: API timeout/)
        expect(Rails.logger).to receive(:error).with(anything)
        service.execute
      end

      it 'returns error response' do
        response = service.execute
        expect(response[:success]).to be false
        expect(response[:error]).to eq('API timeout')
      end
    end
  end

  describe '#agent_name' do
    it 'returns ConversationSummarizer' do
      expect(service.send(:agent_name)).to eq('ConversationSummarizer')
    end
  end

  describe '#build_instructions' do
    it 'renders the summary template' do
      expect(Captain::PromptRenderer).to receive(:render).with('summary', {})
      service.send(:build_instructions)
    end
  end

  describe '#response_schema' do
    let(:schema) { service.send(:response_schema) }

    it 'defines object type' do
      expect(schema[:type]).to eq('object')
    end

    it 'includes customer_intent property' do
      expect(schema[:properties][:customer_intent]).to include(
        type: 'string',
        description: 'Brief description of what the customer wants (around 50 words)'
      )
    end

    it 'includes conversation_summary property' do
      expect(schema[:properties][:conversation_summary]).to include(
        type: 'string',
        description: 'Summary of the conversation in approximately 200 words'
      )
    end

    it 'includes action_items property' do
      expect(schema[:properties][:action_items][:type]).to eq('array')
      expect(schema[:properties][:action_items][:items][:type]).to eq('string')
    end

    it 'includes follow_up_items property' do
      expect(schema[:properties][:follow_up_items][:type]).to eq('array')
      expect(schema[:properties][:follow_up_items][:items][:type]).to eq('string')
    end

    it 'marks required fields' do
      expect(schema[:required]).to match_array(%w[customer_intent conversation_summary])
    end

    it 'disallows additional properties' do
      expect(schema[:additionalProperties]).to be false
    end
  end

  describe '#build_success_response' do
    let(:output) do
      {
        'customer_intent' => 'Reset password',
        'conversation_summary' => 'Password reset conversation',
        'action_items' => ['Item 1', 'Item 2'],
        'follow_up_items' => ['Follow-up 1']
      }
    end

    it 'extracts customer_intent from output' do
      response = service.send(:build_success_response, output)
      expect(response[:structured_data][:customer_intent]).to eq('Reset password')
    end

    it 'extracts conversation_summary from output' do
      response = service.send(:build_success_response, output)
      expect(response[:structured_data][:conversation_summary]).to eq('Password reset conversation')
    end

    it 'extracts action_items from output' do
      response = service.send(:build_success_response, output)
      expect(response[:structured_data][:action_items]).to eq(['Item 1', 'Item 2'])
    end

    it 'extracts follow_up_items from output' do
      response = service.send(:build_success_response, output)
      expect(response[:structured_data][:follow_up_items]).to eq(['Follow-up 1'])
    end

    it 'builds markdown summary' do
      response = service.send(:build_success_response, output)
      expect(response[:summary]).to include('**Customer Intent**')
      expect(response[:summary]).to include('Reset password')
    end

    it 'marks response as successful' do
      response = service.send(:build_success_response, output)
      expect(response[:success]).to be true
    end
  end

  describe '#format_conversation_messages' do
    it 'includes incoming and outgoing messages' do
      text = service.send(:format_conversation_messages)
      expect(text).to include('Customer')
      expect(text).to include('Agent')
    end

    it 'excludes private messages' do
      create(:message, conversation: conversation, message_type: :incoming, content: 'Private note', private: true)
      text = service.send(:format_conversation_messages)
      expect(text).not_to include('Private note')
    end

    it 'respects token limit' do
      long_content = 'a' * 20_000
      create(:message, conversation: conversation, message_type: :incoming, content: long_content)
      text = service.send(:format_conversation_messages)
      expect(text.length).to be <= described_class::TOKEN_LIMIT
    end
  end
end
