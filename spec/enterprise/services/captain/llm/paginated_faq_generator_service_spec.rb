require 'rails_helper'

RSpec.describe Captain::Llm::PaginatedFaqGeneratorService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account) }
  let(:openai_client) { instance_double(OpenAI::Client) }

  let(:service) do
    # Mock the InstallationConfig for base class initialization
    allow(InstallationConfig).to receive(:find_by!).with(name: 'CAPTAIN_OPEN_AI_API_KEY')
                                                   .and_return(instance_double(InstallationConfig, value: 'test-api-key'))
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    described_class.new(document, { pages_per_chunk: 10 })
  end

  describe '#initialize' do
    it 'initializes with document and options' do
      expect(service.instance_variable_get(:@document)).to eq(document)
      expect(service.instance_variable_get(:@pages_per_chunk)).to eq(10)
    end

    it 'uses default pages per chunk when not specified' do
      default_service = described_class.new(document)
      expect(default_service.instance_variable_get(:@pages_per_chunk)).to eq(10)
    end

    it 'accepts max_pages option' do
      service_with_max = described_class.new(document, { max_pages: 50 })
      expect(service_with_max.instance_variable_get(:@max_pages)).to eq(50)
    end
  end

  describe '#generate' do
    context 'when document has no openai_file_id' do
      before do
        allow(document).to receive(:openai_file_id).and_return(nil)
      end

      it 'raises an error' do
        expect { service.generate }.to raise_error('Document must have openai_file_id for paginated processing')
      end
    end

    context 'when document has openai_file_id' do
      before do
        allow(document).to receive(:openai_file_id).and_return('file-123')
      end

      context 'when generating FAQs successfully' do
        let(:faq_response) do
          {
            'choices' => [
              {
                'message' => {
                  'content' => JSON.generate({
                                               'faqs' => [
                                                 { 'question' => 'What is the product?', 'answer' => 'It is a great product.' },
                                                 { 'question' => 'How does it work?', 'answer' => 'It works seamlessly.' }
                                               ],
                                               'has_content' => true
                                             })
                }
              }
            ]
          }
        end

        let(:empty_response) do
          {
            'choices' => [
              {
                'message' => {
                  'content' => JSON.generate({
                                               'faqs' => [],
                                               'has_content' => false
                                             })
                }
              }
            ]
          }
        end

        it 'generates FAQs from document' do
          allow(openai_client).to receive(:chat).and_return(faq_response, empty_response)

          result = service.generate
          expect(result).to be_an(Array)
          expect(result.first).to include('question', 'answer')
        end

        it 'processes multiple chunks until no more content' do
          allow(openai_client).to receive(:chat).and_return(faq_response, faq_response, empty_response)

          result = service.generate
          expect(result.count).to eq(2) # Deduplication removes duplicates
        end

        it 'deduplicates similar FAQs' do
          duplicate_response = {
            'choices' => [
              {
                'message' => {
                  'content' => JSON.generate({
                                               'faqs' => [
                                                 { 'question' => 'What is the product?', 'answer' => 'It is a great product.' },
                                                 { 'question' => 'What is the product?', 'answer' => 'Different answer.' }
                                               ],
                                               'has_content' => false
                                             })
                }
              }
            ]
          }

          allow(openai_client).to receive(:chat).and_return(duplicate_response)

          result = service.generate
          expect(result.count).to eq(1)
        end

        it 'tracks total pages processed' do
          allow(openai_client).to receive(:chat).and_return(faq_response, faq_response, empty_response)

          service.generate
          expect(service.total_pages_processed).to eq(30) # 3 chunks of 10 pages each
        end

        it 'tracks iterations completed' do
          allow(openai_client).to receive(:chat).and_return(faq_response, faq_response, empty_response)

          service.generate
          expect(service.iterations_completed).to eq(3)
        end
      end

      context 'when API returns error' do
        before do
          allow(openai_client).to receive(:chat).and_raise(OpenAI::Error, 'API error')
        end

        it 'returns empty array and logs error' do
          expect(Rails.logger).to receive(:error).with(/Error processing pages/)

          result = service.generate
          expect(result).to eq([])
        end
      end

      context 'when response is malformed' do
        let(:malformed_response) do
          {
            'choices' => [
              {
                'message' => {
                  'content' => 'Invalid JSON'
                }
              }
            ]
          }
        end

        before do
          allow(openai_client).to receive(:chat).and_return(malformed_response)
        end

        it 'handles JSON parsing errors gracefully' do
          expect(Rails.logger).to receive(:error).with(/Error parsing chunk response/)

          result = service.generate
          expect(result).to eq([])
        end
      end
    end
  end

  describe '#should_continue_processing?' do
    let(:chunk_result_with_faqs) { { faqs: [{ 'question' => 'Q1', 'answer' => 'A1' }], has_content: true } }
    let(:chunk_result_empty) { { faqs: [], has_content: false } }

    it 'returns false when max iterations reached' do
      service.instance_variable_set(:@iterations_completed, 20)
      expect(service.should_continue_processing?(chunk_result_with_faqs)).to be false
    end

    it 'returns false when max pages reached' do
      service.instance_variable_set(:@max_pages, 30)
      service.instance_variable_set(:@total_pages_processed, 30)
      expect(service.should_continue_processing?(chunk_result_with_faqs)).to be false
    end

    it 'returns false when no FAQs returned' do
      expect(service.should_continue_processing?({ faqs: [], has_content: true })).to be false
    end

    it 'returns false when has_content is false' do
      expect(service.should_continue_processing?({ faqs: ['faq'], has_content: false })).to be false
    end

    it 'returns true when should continue' do
      expect(service.should_continue_processing?(chunk_result_with_faqs)).to be true
    end
  end

  describe 'private methods' do
    describe '#similarity_score' do
      it 'returns 1 for identical strings' do
        score = service.send(:similarity_score, 'Hello world', 'Hello world')
        expect(score).to eq(1.0)
      end

      it 'returns 0 for completely different strings' do
        score = service.send(:similarity_score, 'Hello', 'Goodbye')
        expect(score).to eq(0.0)
      end

      it 'calculates partial similarity correctly' do
        score = service.send(:similarity_score, 'Hello world', 'Hello there')
        expect(score).to be_between(0.3, 0.4)
      end
    end

    describe '#deduplicate_faqs' do
      let(:faqs_with_duplicates) do
        [
          { 'question' => 'What is the product?', 'answer' => 'Answer 1' },
          { 'question' => 'What is the product?', 'answer' => 'Answer 2' },
          { 'question' => 'What is the product really?', 'answer' => 'Answer 3' },
          { 'question' => 'How does it work?', 'answer' => 'Answer 4' }
        ]
      end

      it 'removes exact duplicates' do
        result = service.send(:deduplicate_faqs, faqs_with_duplicates)
        questions = result.map { |f| f['question'] }
        expect(questions.count('What is the product?')).to eq(1)
      end

      it 'removes similar questions' do
        result = service.send(:deduplicate_faqs, faqs_with_duplicates)
        expect(result.count).to be < faqs_with_duplicates.count
      end
    end

    describe '#determine_stop_reason' do
      it 'identifies max iterations reason' do
        service.instance_variable_set(:@iterations_completed, 20)
        reason = service.send(:determine_stop_reason, { faqs: ['faq'] })
        expect(reason).to eq('Maximum iterations reached')
      end

      it 'identifies max pages reason' do
        service.instance_variable_set(:@max_pages, 30)
        service.instance_variable_set(:@total_pages_processed, 30)
        reason = service.send(:determine_stop_reason, { faqs: ['faq'] })
        expect(reason).to eq('Maximum pages processed')
      end

      it 'identifies no content reason' do
        reason = service.send(:determine_stop_reason, { faqs: [] })
        expect(reason).to eq('No content found in last chunk')
      end

      it 'identifies end of document reason' do
        reason = service.send(:determine_stop_reason, { faqs: ['faq'], has_content: false })
        expect(reason).to eq('End of document reached')
      end
    end

    describe '#calculate_end_page' do
      it 'calculates end page correctly' do
        service.instance_variable_set(:@pages_per_chunk, 10)
        expect(service.send(:calculate_end_page, 1)).to eq(10)
        expect(service.send(:calculate_end_page, 11)).to eq(20)
      end

      it 'respects max_pages limit' do
        service.instance_variable_set(:@pages_per_chunk, 10)
        service.instance_variable_set(:@max_pages, 15)
        expect(service.send(:calculate_end_page, 11)).to eq(15)
      end
    end

    describe '#build_chunk_parameters' do
      before do
        allow(document).to receive(:openai_file_id).and_return('file-123')
        allow(Captain::Llm::SystemPromptsService).to receive(:paginated_faq_generator)
          .and_return('Generate FAQs from pages')
      end

      it 'builds correct parameters structure' do
        params = service.send(:build_chunk_parameters, 1, 10)

        expect(params[:model]).to eq('gpt-4.1-mini')
        expect(params[:response_format]).to eq({ type: 'json_object' })
        expect(params[:messages]).to be_an(Array)
        expect(params[:messages].first[:role]).to eq('user')
      end

      it 'includes file reference and prompt' do
        params = service.send(:build_chunk_parameters, 1, 10)
        user_content = params[:messages].first[:content]

        expect(user_content).to be_an(Array)
        expect(user_content.first[:type]).to eq('file')
        expect(user_content.first[:file][:file_id]).to eq('file-123')
        expect(user_content.last[:type]).to eq('text')
      end
    end
  end
end
