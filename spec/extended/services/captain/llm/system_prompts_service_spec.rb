require 'rails_helper'

RSpec.describe Captain::Llm::SystemPromptsService do
  describe '.faq_generator' do
    it 'returns a prompt string' do
      prompt = described_class.faq_generator
      expect(prompt).to include('You are an expert content analyzer')
      expect(prompt).to include('valid JSON object')
    end

    it 'includes language instruction' do
      prompt = described_class.faq_generator('spanish')
      expect(prompt).to include('spanish')
    end
  end

  describe '.conversation_faq_generator' do
    it 'returns a prompt string' do
      prompt = described_class.conversation_faq_generator
      expect(prompt).to include('Analyze the following support conversation')
      expect(prompt).to include('valid JSON')
    end
  end

  describe '.notes_generator' do
    it 'returns a prompt string' do
      prompt = described_class.notes_generator
      expect(prompt).to include('Summarize the key points')
      expect(prompt).to include('actionable notes')
    end
  end

  describe '.attributes_generator' do
    it 'returns a prompt string' do
      prompt = described_class.attributes_generator
      expect(prompt).to be_a(String)
      expect(prompt).to include('Extract contact attributes')
      expect(prompt).to include('json')
    end
  end

  describe '.copilot_response_generator' do
    it 'returns a prompt string with product name' do
      prompt = described_class.copilot_response_generator('Chatwoot', 'tools')
      expect(prompt).to include('You are Captain')
      expect(prompt).to include('Chatwoot')
    end

    it 'includes citation instructions when configured' do
      prompt = described_class.copilot_response_generator('Chatwoot', 'tools', { 'feature_citation' => true })
      expect(prompt).to include('Cite your sources')
    end
  end

  describe '.assistant_response_generator' do
    it 'returns a prompt string with assistant name' do
      prompt = described_class.assistant_response_generator('Bot', 'Chatwoot')
      expect(prompt).to include('You are Bot')
      expect(prompt).to include('Chatwoot')
    end

    it 'includes custom instructions' do
      prompt = described_class.assistant_response_generator('Bot', 'Chatwoot', { 'instructions' => 'Be polite' })
      expect(prompt).to include('Be polite')
    end
  end

  describe '.paginated_faq_generator' do
    it 'returns a prompt string with page range' do
      prompt = described_class.paginated_faq_generator(1, 5)
      expect(prompt).to include('pages 1-5')
      expect(prompt).to include('Extract FAQs')
    end
  end
end
