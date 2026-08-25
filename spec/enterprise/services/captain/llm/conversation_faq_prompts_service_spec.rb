require 'rails_helper'

RSpec.describe Captain::Llm::ConversationFaqPromptsService do
  describe '.generator' do
    it 'allows a complete FAQ answer to use several related agent messages' do
      prompt = described_class.generator

      expect(prompt).to include('message or messages that together provide a complete public answer')
      expect(prompt).to include('Combine facts only across related agent messages')
      expect(prompt).not_to include('no single human agent message')
    end
  end
end
