require 'rails_helper'

RSpec.describe Captain::Llm::PaginatedFaqGeneratorService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account) }
  let(:service) { described_class.new(document: document, assistant: assistant, requested_faq_count: 10) }

  describe '#initialize' do
    it 'initializes with document, assistant, and requested FAQ count' do
      expect(service.instance_variable_get(:@document)).to eq(document)
      expect(service.instance_variable_get(:@assistant)).to eq(assistant)
      expect(service.instance_variable_get(:@requested_faq_count)).to eq(10)
    end

    it 'uses default FAQ count when not specified' do
      default_service = described_class.new(document: document, assistant: assistant)
      expect(default_service.instance_variable_get(:@requested_faq_count)).to eq(10)
    end

    it 'accepts custom strategy' do
      chunked_service = described_class.new(
        document: document,
        assistant: assistant,
        requested_faq_count: 15,
        strategy: 'chunked'
      )
      expect(chunked_service.instance_variable_get(:@strategy)).to eq('chunked')
    end
  end

  describe '#perform' do
    let(:openai_client) { instance_double(OpenAI::Client) }
    let(:completions_api) { instance_double(OpenAI::Completions) }

    before do
      allow(service).to receive(:openai_client).and_return(openai_client)
      allow(openai_client).to receive(:completions).and_return(completions_api)
    end

    context 'when generating FAQs successfully' do
      let(:faq_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => JSON.generate([
                                             { 'question' => 'What is the product?', 'answer' => 'It is a great product.' },
                                             { 'question' => 'How does it work?', 'answer' => 'It works seamlessly.' },
                                             { 'question' => 'What are the features?', 'answer' => 'Many amazing features.' },
                                             { 'question' => 'Is it secure?', 'answer' => 'Yes, very secure.' },
                                             { 'question' => 'What is the pricing?', 'answer' => 'Competitive pricing.' }
                                           ])
              }
            }
          ]
        }
      end

      before do
        allow(completions_api).to receive(:create).and_return(faq_response)
        allow(service).to receive(:fetch_document_content).and_return('Document content')
      end

      it 'generates requested number of FAQs' do
        result = service.perform
        expect(result[:faqs_generated]).to eq(5)
      end

      it 'returns FAQ data' do
        result = service.perform
        expect(result[:faqs]).to be_an(Array)
        expect(result[:faqs].first).to include('question', 'answer')
      end

      it 'tracks generation metadata' do
        result = service.perform
        expect(result).to include(:faqs_generated, :pages_processed, :generation_time)
      end
    end

    context 'when using pagination for large documents' do
      let(:large_content) { 'Large document content ' * 5000 }

      before do
        allow(service).to receive(:fetch_document_content).and_return(large_content)
        allow(service).to receive(:needs_pagination?).and_return(true)
      end

      it 'processes document in chunks' do
        expect(service).to receive(:generate_faqs_in_chunks).and_call_original

        allow(completions_api).to receive(:create).and_return(
          'choices' => [{ 'message' => { 'content' => '[]' } }]
        )

        service.perform
      end

      it 'aggregates FAQs from multiple pages' do
        page1_faqs = [
          { 'question' => 'Q1', 'answer' => 'A1' },
          { 'question' => 'Q2', 'answer' => 'A2' }
        ]
        page2_faqs = [
          { 'question' => 'Q3', 'answer' => 'A3' },
          { 'question' => 'Q4', 'answer' => 'A4' }
        ]

        allow(completions_api).to receive(:create).and_return(
          { 'choices' => [{ 'message' => { 'content' => JSON.generate(page1_faqs) } }] },
          { 'choices' => [{ 'message' => { 'content' => JSON.generate(page2_faqs) } }] }
        )

        result = service.perform
        expect(result[:faqs]).to eq(page1_faqs + page2_faqs)
        expect(result[:pages_processed]).to eq(2)
      end

      it 'respects requested FAQ count limit' do
        many_faqs = (1..20).map { |i| { 'question' => "Q#{i}", 'answer' => "A#{i}" } }

        allow(completions_api).to receive(:create).and_return(
          'choices' => [{ 'message' => { 'content' => JSON.generate(many_faqs) } }]
        )

        service_with_limit = described_class.new(
          document: document,
          assistant: assistant,
          requested_faq_count: 10
        )
        allow(service_with_limit).to receive(:fetch_document_content).and_return(large_content)

        result = service_with_limit.perform
        expect(result[:faqs].count).to be <= 10
      end
    end

    context 'when using different generation strategies' do
      it 'uses default strategy' do
        allow(service).to receive(:fetch_document_content).and_return('Content')
        expect(service).to receive(:generate_with_default_strategy)

        service.perform
      end

      it 'uses chunked strategy when specified' do
        chunked_service = described_class.new(
          document: document,
          assistant: assistant,
          strategy: 'chunked'
        )
        allow(chunked_service).to receive(:fetch_document_content).and_return('Content')
        expect(chunked_service).to receive(:generate_with_chunked_strategy)

        chunked_service.perform
      end

      it 'uses smart chunking for optimal results' do
        smart_service = described_class.new(
          document: document,
          assistant: assistant,
          strategy: 'smart'
        )
        allow(smart_service).to receive(:fetch_document_content).and_return('Content')
        expect(smart_service).to receive(:generate_with_smart_chunking)

        smart_service.perform
      end
    end

    context 'when generation fails' do
      before do
        allow(service).to receive(:fetch_document_content).and_return('Content')
        allow(completions_api).to receive(:create).and_raise(StandardError, 'API error')
      end

      it 'raises the error' do
        expect { service.perform }.to raise_error(StandardError, 'API error')
      end

      it 'logs the error with context' do
        expect(Rails.logger).to receive(:error).with(/FAQ generation failed for document/)

        expect { service.perform }.to raise_error(StandardError)
      end
    end

    context 'when response is malformed' do
      before do
        allow(service).to receive(:fetch_document_content).and_return('Content')
        allow(completions_api).to receive(:create).and_return(
          'choices' => [{ 'message' => { 'content' => 'Invalid JSON' } }]
        )
      end

      it 'handles JSON parsing errors gracefully' do
        result = service.perform
        expect(result[:faqs]).to eq([])
        expect(result[:error]).to include('Failed to parse FAQ response')
      end
    end
  end

  describe '#fetch_document_content' do
    context 'when document has PDF file' do
      before do
        document.pdf_file.attach(
          io: StringIO.new('PDF content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        document.metadata['openai_file_id'] = 'file-123'
        document.save!
      end

      it 'retrieves content from OpenAI files' do
        openai_client = instance_double(OpenAI::Client)
        files_api = instance_double(OpenAI::Files)

        allow(service).to receive(:openai_client).and_return(openai_client)
        allow(openai_client).to receive(:files).and_return(files_api)
        allow(files_api).to receive(:content).with(id: 'file-123').and_return('PDF text content')

        content = service.send(:fetch_document_content)
        expect(content).to eq('PDF text content')
      end
    end

    context 'when document has external link' do
      before do
        document.update!(external_link: 'https://example.com/doc')
      end

      it 'fetches content from URL' do
        expect(service).to receive(:fetch_url_content).with('https://example.com/doc').and_return('Web content')

        content = service.send(:fetch_document_content)
        expect(content).to eq('Web content')
      end
    end
  end

  describe '#needs_pagination?' do
    it 'returns true for large content' do
      large_content = 'a' * 50_000
      expect(service.send(:needs_pagination?, large_content)).to be true
    end

    it 'returns false for small content' do
      small_content = 'a' * 1000
      expect(service.send(:needs_pagination?, small_content)).to be false
    end

    it 'uses configurable threshold' do
      allow(service).to receive(:pagination_threshold).and_return(100)

      expect(service.send(:needs_pagination?, 'a' * 101)).to be true
      expect(service.send(:needs_pagination?, 'a' * 99)).to be false
    end
  end

  describe '#chunk_content' do
    let(:content) { 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5' }

    it 'splits content into chunks' do
      chunks = service.send(:chunk_content, content, chunk_size: 2)
      expect(chunks.count).to eq(3)
    end

    it 'maintains chunk size limit' do
      chunks = service.send(:chunk_content, content, chunk_size: 3)
      expect(chunks[0]).to eq("Line 1\nLine 2\nLine 3")
      expect(chunks[1]).to eq("Line 4\nLine 5")
    end

    it 'handles overlap between chunks' do
      chunks = service.send(:chunk_content, content, chunk_size: 3, overlap: 1)
      expect(chunks[0]).to eq("Line 1\nLine 2\nLine 3")
      expect(chunks[1]).to eq("Line 3\nLine 4\nLine 5")
    end
  end

  describe '#build_faq_prompt' do
    it 'includes document content in prompt' do
      prompt = service.send(:build_faq_prompt, 'Document content', 5)
      expect(prompt).to include('Document content')
    end

    it 'specifies requested FAQ count' do
      prompt = service.send(:build_faq_prompt, 'Content', 7)
      expect(prompt).to include('7')
    end

    it 'includes JSON format instructions' do
      prompt = service.send(:build_faq_prompt, 'Content', 5)
      expect(prompt).to include('JSON')
      expect(prompt).to include('question')
      expect(prompt).to include('answer')
    end
  end

  describe '#parse_faq_response' do
    it 'parses valid JSON array' do
      json_string = '[{"question": "Q1", "answer": "A1"}]'
      result = service.send(:parse_faq_response, json_string)
      expect(result).to eq([{ 'question' => 'Q1', 'answer' => 'A1' }])
    end

    it 'handles empty response' do
      result = service.send(:parse_faq_response, '[]')
      expect(result).to eq([])
    end

    it 'returns empty array for invalid JSON' do
      result = service.send(:parse_faq_response, 'not json')
      expect(result).to eq([])
    end

    it 'validates FAQ structure' do
      invalid_faqs = '[{"q": "Question without proper key"}]'
      result = service.send(:parse_faq_response, invalid_faqs)
      expect(result).to eq([])
    end
  end

  describe 'performance tracking' do
    before do
      allow(service).to receive(:fetch_document_content).and_return('Content')
      allow(service).to receive(:generate_faqs).and_return([])
    end

    it 'tracks generation time' do
      result = service.perform
      expect(result[:generation_time]).to be_a(Float)
      expect(result[:generation_time]).to be >= 0
    end

    it 'tracks number of API calls' do
      allow(service).to receive(:needs_pagination?).and_return(true)
      allow(service).to receive(:chunk_content).and_return(%w[chunk1 chunk2])

      result = service.perform
      expect(result[:api_calls]).to eq(2)
    end
  end
end
