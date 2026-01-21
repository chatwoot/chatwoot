require 'rails_helper'

RSpec.describe Captain::FollowUpService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user_message) { 'Make it more concise' }
  let(:follow_up_context) do
    {
      'event_name' => 'professional',
      'original_context' => 'Please help me with this issue',
      'last_response' => 'I would be happy to assist you with this matter.',
      'conversation_history' => [
        { 'role' => 'user', 'content' => 'Make it shorter' },
        { 'role' => 'assistant', 'content' => 'Happy to help with this.' }
      ]
    }
  end
  let(:service) do
    described_class.new(
      account: account,
      follow_up_context: follow_up_context,
      user_message: user_message,
      conversation_display_id: conversation.display_id
    )
  end

  before do
    # Stub captain enabled check to allow specs to test base functionality
    # without enterprise module interference
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  describe '#perform' do
    context 'when conversation_display_id is provided' do
      it 'resolves conversation for instrumentation' do
        expect(service.send(:conversation)).to eq(conversation)
      end
    end

    context 'when follow-up context exists' do
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

      it 'returns updated follow-up context' do
        allow(service).to receive(:make_api_call).and_return({ message: 'Refined response' })

        result = service.perform

        expect(result[:message]).to eq('Refined response')
        expect(result[:follow_up_context]['last_response']).to eq('Refined response')
        expect(result[:follow_up_context]['conversation_history'].length).to eq(4)
        expect(result[:follow_up_context]['conversation_history'][-2]['content']).to eq('Make it more concise')
        expect(result[:follow_up_context]['conversation_history'][-1]['content']).to eq('Refined response')
      end
    end

    context 'when follow-up context is missing' do
      let(:follow_up_context) { nil }

      it 'returns error with 400 code' do
        result = service.perform

        expect(result[:error]).to eq('Follow-up context missing')
        expect(result[:error_code]).to eq(400)
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
end
