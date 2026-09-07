require 'rails_helper'

RSpec.describe Captain::Llm::ConversationFaqService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:conversation) { create(:conversation, account: captain_assistant.account, first_reply_created_at: Time.zone.now) }
  let(:service) { described_class.new(captain_assistant, conversation) }
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:sample_faqs) do
    [
      { 'question' => 'What is the purpose?', 'answer' => 'To help users.' },
      { 'question' => 'How does it work?', 'answer' => 'Through AI.' }
    ]
  end
  let(:mock_response) do
    instance_double(RubyLLM::Message, content: { faqs: sample_faqs }.to_json)
  end
  let(:embedding_one) { [1.0] + Array.new(1535, 0.0) }
  let(:embedding_two) { [0.0, 1.0] + Array.new(1534, 0.0) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
    allow(mock_chat).to receive(:with_params).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#generate_suggestions' do
    context 'when successful' do
      before do
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one, embedding_two)
      end

      it 'uses the conversation FAQ generation feature model' do
        expect(RubyLLM).to receive(:chat).with(
          model: Llm::Models.default_model_for('conversation_faq_generation')
        ).and_return(mock_chat)

        described_class.new(captain_assistant, conversation).generate_suggestions
      end

      it 'uses the conversation FAQ default ahead of the legacy global installation model' do
        create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-mini')

        expect(RubyLLM).to receive(:chat).with(
          model: Llm::Models.default_model_for('conversation_faq_generation')
        ).and_return(mock_chat)

        described_class.new(captain_assistant, conversation).generate_suggestions
      end

      it 'keeps account conversation FAQ model overrides ahead of the feature default' do
        create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1')
        conversation.account.update!(captain_models: { 'conversation_faq_generation' => 'gpt-4.1-mini' })

        expect(RubyLLM).to receive(:chat).with(model: 'gpt-4.1-mini').and_return(mock_chat)

        described_class.new(captain_assistant, conversation).generate_suggestions
      end

      it 'resolves the feature model from the conversation account' do
        expect(Llm::FeatureRouter).to receive(:resolve).with(
          feature: 'conversation_faq_generation',
          account: conversation.account
        ).and_call_original

        described_class.new(captain_assistant, conversation).generate_suggestions
      end

      it 'sends only customer and human support agent messages to the LLM' do
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         sender: create(:contact, account: conversation.account), message_type: :incoming,
                         content: 'Customer question')
        create(:message, :bot_message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                                       content: 'Bot answer that should not become knowledge')
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         sender: create(:user, account: conversation.account), message_type: :outgoing,
                         content: 'Human answer')
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         sender: create(:user, account: conversation.account), message_type: :outgoing,
                         private: true, content: 'Private note')
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         message_type: :activity, content: 'Activity message')

        service.generate_suggestions

        expected_content = satisfy do |content|
          content.include?('User: Customer question') &&
            content.include?('Support Agent: Human answer') &&
            content.exclude?('Bot answer that should not become knowledge') &&
            content.exclude?('Private note') &&
            content.exclude?('Activity message')
        end
        expect(mock_chat).to have_received(:ask).with(expected_content)
      end

      it 'keeps external echo outgoing replies from native channels in the LLM transcript' do
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         sender: create(:contact, account: conversation.account), message_type: :incoming,
                         content: 'Customer asks in a native channel')
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         sender: nil, message_type: :outgoing, content: 'Human replied from the native app',
                         content_attributes: { external_echo: true })

        service.generate_suggestions

        expected_content = satisfy do |content|
          content.include?('User: Customer asks in a native channel') &&
            content.include?('Support Agent: Human replied from the native app')
        end
        expect(mock_chat).to have_received(:ask).with(expected_content)
      end

      it 'uses the human-only conversation transcript for instrumentation' do
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         sender: create(:contact, account: conversation.account), message_type: :incoming,
                         content: 'Customer asks something')
        create(:message, :bot_message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                                       content: 'Bot-only answer')
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox,
                         sender: create(:user, account: conversation.account), message_type: :outgoing,
                         content: 'Agent gives a public answer')

        expect(service).to receive(:instrument_llm_call) do |params, &block|
          user_message = params[:messages].find { |message| message[:role] == 'user' }[:content]

          expect(user_message).to include('User: Customer asks something')
          expect(user_message).to include('Support Agent: Agent gives a public answer')
          expect(user_message).not_to include('Bot-only answer')

          block.call
        end

        service.generate_suggestions
      end

      it 'creates suggestions instead of trusted FAQs for valid conversation content' do
        expect do
          service.generate_suggestions
        end.to change(captain_assistant.faq_suggestions, :count).by(2)
        expect(Captain::FaqObservation.count).to eq(2)
        expect(captain_assistant.responses.count).to be_zero
      end

      it 'saves open suggestions with one attached source each' do
        service.generate_suggestions
        expect(
          captain_assistant.faq_suggestions.pluck(:question, :answer, :status, :source_count, :language)
        ).to contain_exactly(
          ['What is the purpose?', 'To help users.', 'open', 1, 'en'],
          ['How does it work?', 'Through AI.', 'open', 1, 'en']
        )
        expect(Captain::FaqObservation.attached.pluck(:conversation_id, :language)).to contain_exactly(
          [conversation.id, 'en'], [conversation.id, 'en']
        )
      end
    end

    context 'without human interaction' do
      let(:conversation) { create(:conversation) }

      it 'returns an empty array without generating FAQs' do
        expect(service.generate_suggestions).to eq([])
      end

      it 'does not call the LLM API' do
        expect(RubyLLM).not_to receive(:chat)
        service.generate_suggestions
      end
    end

    context 'when finding duplicates' do
      let(:existing_response) do
        create(:captain_assistant_response, assistant: captain_assistant, account: captain_assistant.account,
                                            question: 'Similar question', answer: 'Similar answer', embedding: embedding_one)
      end
      let(:match_response) { instance_double(RubyLLM::Message, content: { same_faq: true }.to_json) }

      before do
        existing_response
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
        allow(mock_chat).to receive(:ask) do |input|
          input.start_with?('{') ? match_response : mock_response
        end
      end

      it 'discards candidates the LLM confirms are covered by an approved FAQ' do
        expect do
          service.generate_suggestions
        end.to change(Captain::FaqObservation.discarded, :count).by(2)
        expect(captain_assistant.faq_suggestions.count).to be_zero
      end

      it 'uses the conversation FAQ matching feature model' do
        expect(RubyLLM).to receive(:chat).with(
          model: Llm::Models.default_model_for('conversation_faq_matching')
        ).at_least(:once).and_return(mock_chat)

        service.generate_suggestions
      end

      it 'uses the account model override for conversation FAQ matching' do
        conversation.account.update!(captain_models: { 'conversation_faq_matching' => 'gpt-5-mini' })

        expect(RubyLLM).to receive(:chat).with(model: 'gpt-5-mini').at_least(:once).and_return(mock_chat)

        service.generate_suggestions
      end

      it 'resolves the matching feature model from the conversation account' do
        allow(Llm::FeatureRouter).to receive(:resolve).and_call_original
        expect(Llm::FeatureRouter).to receive(:resolve).with(
          feature: 'conversation_faq_matching',
          account: conversation.account
        ).and_call_original

        service.generate_suggestions
      end
    end

    context 'when FAQ comparison cannot be completed' do
      let(:existing_response) do
        create(:captain_assistant_response, assistant: captain_assistant, account: captain_assistant.account,
                                            question: 'Similar question', answer: 'Similar answer', embedding: embedding_one)
      end
      let(:comparison_response) { instance_double(RubyLLM::Message, content: comparison_response_content) }
      let(:comparison_response_content) { 'invalid json' }

      before do
        existing_response
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
        allow(mock_chat).to receive(:ask) do |input|
          input.start_with?('{') ? comparison_response : mock_response
        end
        allow(Rails.logger).to receive(:error)
      end

      it 'raises when the comparison response is malformed' do
        expect do
          service.generate_suggestions
        end.to raise_error(JSON::ParserError)
        expect(captain_assistant.faq_suggestions.count).to be_zero
      end

      context 'when the response omits the comparison result' do
        let(:comparison_response_content) { {}.to_json }

        it 'raises instead of treating the response as a non-match' do
          expect do
            service.generate_suggestions
          end.to raise_error(KeyError)
          expect(captain_assistant.faq_suggestions.count).to be_zero
        end
      end

      context 'when the comparison result is not a boolean' do
        let(:comparison_response_content) { { same_faq: 'false' }.to_json }

        it 'raises instead of treating the response as a non-match' do
          expect do
            service.generate_suggestions
          end.to raise_error(TypeError, 'same_faq must be a boolean')
          expect(captain_assistant.faq_suggestions.count).to be_zero
        end
      end

      context 'when the comparison provider fails' do
        before do
          allow(mock_chat).to receive(:ask) do |input|
            raise RubyLLM::Error.new(nil, 'API Error') if input.start_with?('{')

            mock_response
          end
        end

        it 'raises instead of treating the failure as a non-match' do
          expect do
            service.generate_suggestions
          end.to raise_error(RubyLLM::Error)
          expect(captain_assistant.faq_suggestions.count).to be_zero
        end
      end
    end

    context 'when the classifier confirms a non-match' do
      let(:sample_faqs) { [{ 'question' => 'How can I use the feature?', 'answer' => 'Enable it in settings.' }] }
      let(:match_response) { instance_double(RubyLLM::Message, content: { same_faq: false }.to_json) }

      before do
        create(:captain_assistant_response, assistant: captain_assistant, account: captain_assistant.account,
                                            question: 'How do I enable the feature?', answer: 'Turn it on in settings.',
                                            embedding: embedding_one)
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
        allow(mock_chat).to receive(:ask) do |input|
          input.start_with?('{') ? match_response : mock_response
        end
      end

      it 'creates a new suggestion' do
        expect do
          service.generate_suggestions
        end.to change(captain_assistant.faq_suggestions, :count).by(1)
      end
    end

    context 'when an open suggestion is the same FAQ' do
      let(:sample_faqs) { [{ 'question' => 'How can I use the feature?', 'answer' => 'Enable it in settings.' }] }
      let(:existing_suggestion) do
        captain_assistant.faq_suggestions.create!(
          question: 'How do I enable the feature?',
          answer: 'Turn it on in settings.',
          embedding: embedding_one
        ).tap do |suggestion|
          suggestion.observations.create!(
            conversation: create(:conversation, account: captain_assistant.account),
            generated_question: suggestion.question,
            generated_answer: suggestion.answer,
            language: suggestion.language
          )
          suggestion.update!(source_count: suggestion.observations.attached.count)
        end
      end
      let(:match_response) { instance_double(RubyLLM::Message, content: { same_faq: true }.to_json) }

      before do
        existing_suggestion
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
        allow(mock_chat).to receive(:ask) do |input|
          input.start_with?('{') ? match_response : mock_response
        end
      end

      it 'attaches the observation and increments the source count' do
        expect do
          service.generate_suggestions
        end.to change(existing_suggestion.observations, :count).by(1)
        expect(existing_suggestion.reload.source_count).to eq(2)
        expect(captain_assistant.faq_suggestions.count).to eq(1)
      end

      it 'does not attach the observation when the suggestion changes after classification' do
        allow(mock_chat).to receive(:ask) do |input|
          if input.start_with?('{')
            existing_suggestion.update!(question: 'Edited after classification started')
            match_response
          else
            mock_response
          end
        end

        expect do
          service.generate_suggestions
        end.to raise_error(described_class::SuggestionChangedError)
        expect(existing_suggestion.observations.count).to eq(1)
        expect(existing_suggestion.reload.source_count).to eq(1)
      end
    end

    context 'when a similar open suggestion uses another language' do
      let(:sample_faqs) { [{ 'question' => 'Como ativo o recurso?', 'answer' => 'Ative nas configuracoes.' }] }
      let!(:existing_suggestion) do
        captain_assistant.faq_suggestions.create!(question: 'How do I enable the feature?', answer: 'Turn it on in settings.',
                                                  embedding: embedding_one, language: 'en', source_count: 1)
      end

      before do
        conversation.update!(additional_attributes: { conversation_language: 'pt-BR' })
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
      end

      it 'creates a separate suggestion in the conversation language' do
        expect do
          service.generate_suggestions
        end.to change(captain_assistant.faq_suggestions, :count).by(1)

        expect(captain_assistant.faq_suggestions.pluck(:language)).to contain_exactly('en', 'pt')
        expect(existing_suggestion.reload.source_count).to eq(1)
      end
    end

    context 'when an open suggestion uses another locale variant of the same language' do
      let(:account) { create(:account, locale: 'pt_BR') }
      let(:captain_assistant) { create(:captain_assistant, account: account) }
      let(:conversation) { create(:conversation, account: account, first_reply_created_at: Time.zone.now) }
      let(:sample_faqs) { [{ 'question' => 'Como ativo o recurso?', 'answer' => 'Ative nas configuracoes.' }] }
      let(:existing_suggestion) do
        captain_assistant.faq_suggestions.create!(
          question: 'Como habilito o recurso?',
          answer: 'Ative nas configuracoes.',
          embedding: embedding_one,
          language: 'pt',
          source_count: 1
        )
      end
      let(:match_response) { instance_double(RubyLLM::Message, content: { same_faq: true }.to_json) }

      before do
        existing_suggestion
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
        allow(mock_chat).to receive(:ask) do |input|
          input.start_with?('{') ? match_response : mock_response
        end
      end

      it 'attaches the observation to the existing base-language suggestion' do
        expect do
          service.generate_suggestions
        end.to change(existing_suggestion.observations, :count).by(1)

        expect(existing_suggestion.reload.source_count).to eq(2)
        expect(captain_assistant.faq_suggestions.count).to eq(1)
        expect(existing_suggestion.observations.last.language).to eq('pt')
      end
    end

    context 'when a similar approved FAQ uses another language' do
      let(:sample_faqs) { [{ 'question' => 'Como ativo o recurso?', 'answer' => 'Ative nas configuracoes.' }] }
      let(:match_response) { instance_double(RubyLLM::Message, content: { same_faq: true }.to_json) }

      before do
        create(:captain_assistant_response, assistant: captain_assistant, account: captain_assistant.account,
                                            question: 'How do I enable the feature?', answer: 'Turn it on in settings.',
                                            embedding: embedding_one)
        conversation.update!(additional_attributes: { conversation_language: 'pt-BR' })
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
        allow(mock_chat).to receive(:ask) do |input|
          input.start_with?('{') ? match_response : mock_response
        end
      end

      it 'deduplicates against the approved FAQ' do
        expect do
          service.generate_suggestions
        end.to change(Captain::FaqObservation.discarded, :count).by(1)
        expect(captain_assistant.faq_suggestions.count).to be_zero
      end
    end

    context 'when conversation and account locales share a base language' do
      let(:account) { create(:account, locale: 'pt_BR') }
      let(:captain_assistant) { create(:captain_assistant, account: account) }
      let(:conversation) do
        create(:conversation, account: account, first_reply_created_at: Time.zone.now,
                              additional_attributes: { conversation_language: 'pt' })
      end
      let!(:existing_response) do
        create(:captain_assistant_response, assistant: captain_assistant, account: account,
                                            question: 'Como ativo o recurso?', answer: 'Ative nas configuracoes.',
                                            embedding: embedding_one)
      end
      let(:match_response) { instance_double(RubyLLM::Message, content: { same_faq: true }.to_json) }

      before do
        existing_response
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one)
        allow(mock_chat).to receive(:ask) do |input|
          input.start_with?('{') ? match_response : mock_response
        end
      end

      it 'deduplicates against approved FAQs in the same base language' do
        expect do
          service.generate_suggestions
        end.to change(Captain::FaqObservation.discarded, :count).by(2)
        expect(captain_assistant.faq_suggestions.count).to be_zero
      end
    end

    context 'when LLM API fails' do
      before do
        allow(mock_chat).to receive(:ask).and_raise(RubyLLM::Error.new(nil, 'API Error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'returns empty array and logs the error' do
        expect(Rails.logger).to receive(:error).with('LLM API Error: API Error')
        expect(service.generate_suggestions).to eq([])
      end
    end

    context 'when JSON parsing fails' do
      let(:invalid_response) do
        instance_double(RubyLLM::Message, content: 'invalid json')
      end

      before do
        allow(mock_chat).to receive(:ask).and_return(invalid_response)
      end

      it 'handles JSON parsing errors gracefully' do
        expect(Rails.logger).to receive(:error).with(/Error in parsing GPT processed response:/)
        expect(service.generate_suggestions).to eq([])
      end
    end

    context 'when response content is nil' do
      let(:nil_response) do
        instance_double(RubyLLM::Message, content: nil)
      end

      before do
        allow(mock_chat).to receive(:ask).and_return(nil_response)
      end

      it 'returns empty array' do
        expect(service.generate_suggestions).to eq([])
      end
    end
  end

  describe 'language handling' do
    context 'when conversation has different language' do
      let(:account) { create(:account, locale: 'fr') }
      let(:captain_assistant) { create(:captain_assistant, account: account) }
      let(:conversation) do
        create(:conversation, account: account, first_reply_created_at: Time.zone.now)
      end

      before do
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one, embedding_two)
      end

      it 'uses account language for system prompt' do
        expect(Captain::Llm::ConversationFaqPromptsService).to receive(:generator)
          .with('french')
          .at_least(:once)
          .and_call_original

        service.generate_suggestions
      end
    end

    context 'when conversation language differs from account language' do
      let(:account) { create(:account, locale: 'en') }
      let(:captain_assistant) { create(:captain_assistant, account: account) }
      let(:conversation) do
        create(:conversation, account: account, first_reply_created_at: Time.zone.now,
                              additional_attributes: { conversation_language: 'pt-BR' })
      end

      before do
        allow(embedding_service).to receive(:get_embedding).and_return(embedding_one, embedding_two)
      end

      it 'uses the conversation language for the system prompt' do
        expect(Captain::Llm::ConversationFaqPromptsService).to receive(:generator)
          .with('portuguese')
          .at_least(:once)
          .and_call_original

        service.generate_suggestions
      end
    end
  end
end
