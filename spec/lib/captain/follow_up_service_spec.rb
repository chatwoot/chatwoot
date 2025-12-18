require 'rails_helper'

RSpec.describe Captain::FollowUpService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:session_id) { SecureRandom.uuid }
  let(:user_message) { 'Make it more concise' }
  let(:service) { described_class.new(account: account, session_id: session_id, user_message: user_message) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }
  let(:mock_response) { instance_double(RubyLLM::Message, content: 'Refined response', input_tokens: 15, output_tokens: 10) }

  let(:session_data) do
    {
      'event_name' => 'professional',
      'original_context' => 'Please help me with this issue',
      'last_response' => 'I would be happy to assist you with this matter.',
      'conversation_history' => [
        { 'role' => 'user', 'content' => 'Make it shorter' },
        { 'role' => 'assistant', 'content' => 'Happy to help with this.' }
      ],
      'conversation_display_id' => conversation.display_id,
      'created_at' => Time.current.to_i
    }
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_instructions)
    allow(mock_chat).to receive(:add_message)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#perform' do
    context 'when session exists' do
      before do
        Redis::Alfred.setex(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          session_data.to_json,
          1.hour.to_i
        )
      end

      it 'loads session data from Redis' do
        expect(Redis::Alfred).to receive(:get).with("CAPTAIN_TASK_SESSION::#{session_id}").and_call_original
        service.perform
      end

      it 'builds follow-up system prompt with action context' do
        result = service.perform
        expect(result[:message]).to eq('Refined response')
      end

      it 'constructs messages array with full conversation history' do
        expect(service).to receive(:make_api_call) do |args|
          messages = args[:messages]

          expect(messages).to match(
            [
              a_hash_including(role: 'system', content: include('tone rewrite (professional)')),
              { role: 'user', content: 'Please help me with this issue' },
              { role: 'assistant', content: 'I would be happy to assist you with this matter.' },
              { role: 'user', content: 'Make it shorter' },
              { role: 'assistant', content: 'Happy to help with this.' },
              { role: 'user', content: 'Make it more concise' }
            ]
          )

          { message: 'Refined response' }
        end

        service.perform
      end

      it 'converts conversation history from string keys to symbol keys' do
        expect(mock_chat).to receive(:add_message).with(role: :user, content: 'Please help me with this issue').ordered
        expect(mock_chat).to receive(:add_message).with(role: :assistant, content: 'I would be happy to assist you with this matter.').ordered
        expect(mock_chat).to receive(:add_message).with(role: :user, content: 'Make it shorter').ordered
        expect(mock_chat).to receive(:add_message).with(role: :assistant, content: 'Happy to help with this.').ordered
        expect(mock_chat).to receive(:ask).with('Make it more concise').and_return(mock_response)

        service.perform
      end

      it 'updates session with new exchange' do
        expect(Redis::Alfred).to receive(:setex).with(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          anything,
          1.hour.to_i
        ).and_call_original

        service.perform

        updated_session = JSON.parse(Redis::Alfred.get("CAPTAIN_TASK_SESSION::#{session_id}"))
        expect(updated_session['conversation_history'].length).to eq(4)
        expect(updated_session['conversation_history'][-2]['content']).to eq('Make it more concise')
        expect(updated_session['conversation_history'][-1]['content']).to eq('Refined response')
        expect(updated_session['last_response']).to eq('Refined response')
      end

      it 'extends session TTL to 1 hour on each follow-up' do
        expect(Redis::Alfred).to receive(:setex).with(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          anything,
          1.hour.to_i
        )

        service.perform
      end

      it 'returns response with session_id' do
        result = service.perform

        expect(result[:message]).to eq('Refined response')
        expect(result[:session_id]).to eq(session_id)
        expect(result[:usage]['prompt_tokens']).to eq(15)
        expect(result[:usage]['completion_tokens']).to eq(10)
        expect(result[:usage]['total_tokens']).to eq(25)
      end
    end

    context 'when session does not exist' do
      it 'returns error with 404 code' do
        result = service.perform

        expect(result[:error]).to eq('Session expired or not found')
        expect(result[:error_code]).to eq(404)
      end

      it 'does not call API when session is missing' do
        expect(service).not_to receive(:make_api_call)
        service.perform
      end
    end

    context 'when session data is invalid JSON' do
      before do
        Redis::Alfred.setex(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          'invalid json{',
          1.hour.to_i
        )
      end

      it 'returns error with 404 code' do
        result = service.perform

        expect(result[:error]).to eq('Session expired or not found')
        expect(result[:error_code]).to eq(404)
      end
    end

    context 'when API call fails' do
      before do
        Redis::Alfred.setex(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          session_data.to_json,
          1.hour.to_i
        )

        allow(service).to receive(:make_api_call).and_return({ error: 'API timeout' })
      end

      it 'returns error response without updating session' do
        expect(Redis::Alfred).not_to receive(:setex)

        result = service.perform
        expect(result[:error]).to eq('API timeout')
      end
    end

    context 'with empty conversation history' do
      let(:session_data_no_history) do
        {
          'event_name' => 'improve',
          'original_context' => 'Draft message',
          'last_response' => 'Improved draft',
          'conversation_history' => [],
          'conversation_display_id' => conversation.display_id,
          'created_at' => Time.current.to_i
        }
      end

      before do
        Redis::Alfred.setex(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          session_data_no_history.to_json,
          1.hour.to_i
        )
      end

      it 'constructs messages without history' do
        expect(service).to receive(:make_api_call) do |args|
          messages = args[:messages]

          expect(messages).to match(
            [
              a_hash_including(role: 'system'),
              { role: 'user', content: 'Draft message' },
              { role: 'assistant', content: 'Improved draft' },
              { role: 'user', content: 'Make it more concise' }
            ]
          )

          { message: 'More concise' }
        end

        service.perform
      end
    end
  end

  describe '#build_follow_up_system_prompt' do
    it 'describes tone rewrite actions' do
      %w[professional casual friendly confident straightforward].each do |tone|
        session = { 'event_name' => tone }
        prompt = service.send(:build_follow_up_system_prompt, session)

        expect(prompt).to include("tone rewrite (#{tone})")
        expect(prompt).to include('help them refine the result')
      end
    end

    it 'describes fix_spelling_grammar action' do
      session = { 'event_name' => 'fix_spelling_grammar' }
      prompt = service.send(:build_follow_up_system_prompt, session)

      expect(prompt).to include('spelling and grammar correction')
    end

    it 'describes improve action' do
      session = { 'event_name' => 'improve' }
      prompt = service.send(:build_follow_up_system_prompt, session)

      expect(prompt).to include('message improvement')
    end

    it 'describes summarize action' do
      session = { 'event_name' => 'summarize' }
      prompt = service.send(:build_follow_up_system_prompt, session)

      expect(prompt).to include('conversation summary')
    end

    it 'describes reply_suggestion action' do
      session = { 'event_name' => 'reply_suggestion' }
      prompt = service.send(:build_follow_up_system_prompt, session)

      expect(prompt).to include('reply suggestion')
    end

    it 'describes label_suggestion action' do
      session = { 'event_name' => 'label_suggestion' }
      prompt = service.send(:build_follow_up_system_prompt, session)

      expect(prompt).to include('label suggestion')
    end

    it 'uses event_name directly for unknown actions' do
      session = { 'event_name' => 'custom_action' }
      prompt = service.send(:build_follow_up_system_prompt, session)

      expect(prompt).to include('custom_action')
    end
  end

  describe '#describe_previous_action' do
    it 'returns tone description for tone operations' do
      expect(service.send(:describe_previous_action, 'professional')).to eq('tone rewrite (professional)')
      expect(service.send(:describe_previous_action, 'casual')).to eq('tone rewrite (casual)')
      expect(service.send(:describe_previous_action, 'friendly')).to eq('tone rewrite (friendly)')
      expect(service.send(:describe_previous_action, 'confident')).to eq('tone rewrite (confident)')
      expect(service.send(:describe_previous_action, 'straightforward')).to eq('tone rewrite (straightforward)')
    end

    it 'returns specific descriptions for other operations' do
      expect(service.send(:describe_previous_action, 'fix_spelling_grammar')).to eq('spelling and grammar correction')
      expect(service.send(:describe_previous_action, 'improve')).to eq('message improvement')
      expect(service.send(:describe_previous_action, 'summarize')).to eq('conversation summary')
      expect(service.send(:describe_previous_action, 'reply_suggestion')).to eq('reply suggestion')
      expect(service.send(:describe_previous_action, 'label_suggestion')).to eq('label suggestion')
    end

    it 'returns event name for unknown operations' do
      expect(service.send(:describe_previous_action, 'unknown')).to eq('unknown')
    end
  end

  describe '#load_session' do
    context 'when session exists with valid JSON' do
      before do
        Redis::Alfred.setex(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          session_data.to_json,
          1.hour.to_i
        )
      end

      it 'returns parsed session data' do
        result = service.send(:load_session)

        expect(result).to be_a(Hash)
        expect(result['event_name']).to eq('professional')
        expect(result['original_context']).to eq('Please help me with this issue')
        expect(result['conversation_history']).to be_an(Array)
        expect(result['conversation_history'].length).to eq(2)
      end
    end

    context 'when session does not exist' do
      it 'returns nil' do
        result = service.send(:load_session)
        expect(result).to be_nil
      end
    end

    context 'when session contains invalid JSON' do
      before do
        Redis::Alfred.setex(
          "CAPTAIN_TASK_SESSION::#{session_id}",
          'not valid json',
          1.hour.to_i
        )
      end

      it 'returns nil' do
        result = service.send(:load_session)
        expect(result).to be_nil
      end
    end
  end

  describe '#update_session' do
    let(:existing_session) do
      {
        'event_name' => 'professional',
        'original_context' => 'Original',
        'last_response' => 'Previous response',
        'conversation_history' => [
          { 'role' => 'user', 'content' => 'First follow-up' },
          { 'role' => 'assistant', 'content' => 'First refinement' }
        ],
        'conversation_display_id' => conversation.display_id,
        'created_at' => Time.current.to_i
      }
    end

    it 'appends user and assistant messages to history' do
      service.send(:update_session, existing_session, 'Second follow-up', 'Second refinement')

      updated = JSON.parse(Redis::Alfred.get("CAPTAIN_TASK_SESSION::#{session_id}"))
      expect(updated['conversation_history'].length).to eq(4)
      expect(updated['conversation_history'][-2]).to eq({ 'role' => 'user', 'content' => 'Second follow-up' })
      expect(updated['conversation_history'][-1]).to eq({ 'role' => 'assistant', 'content' => 'Second refinement' })
    end

    it 'updates last_response with new assistant message' do
      service.send(:update_session, existing_session, 'User msg', 'New response')

      updated = JSON.parse(Redis::Alfred.get("CAPTAIN_TASK_SESSION::#{session_id}"))
      expect(updated['last_response']).to eq('New response')
    end

    it 'preserves other session fields' do
      service.send(:update_session, existing_session, 'User msg', 'Assistant msg')

      updated = JSON.parse(Redis::Alfred.get("CAPTAIN_TASK_SESSION::#{session_id}"))
      expect(updated['event_name']).to eq('professional')
      expect(updated['original_context']).to eq('Original')
      expect(updated['conversation_display_id']).to eq(conversation.display_id)
    end
  end

  describe '#event_name' do
    it 'returns follow_up' do
      expect(service.send(:event_name)).to eq('follow_up')
    end
  end
end
