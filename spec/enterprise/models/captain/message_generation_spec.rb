require 'rails_helper'

RSpec.describe Captain::MessageGeneration, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }

    it 'resolves the conversation association to the top-level Conversation model' do
      # `Captain::Conversation` exists as a job namespace, so without an explicit
      # class_name the association would resolve to that module instead.
      expect(described_class.reflect_on_association(:conversation).klass).to eq(Conversation)
    end
  end

  describe 'callbacks' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:message) { create(:message, account: account, conversation: conversation) }
    let(:assistant) { create(:captain_assistant, account: account) }

    it 'derives the account and conversation from the message' do
      generation = described_class.create!(message: message, assistant: assistant)

      expect(generation.account).to eq(account)
      expect(generation.conversation).to eq(conversation)
    end
  end

  describe '.record!' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:message) { create(:message, account: account, conversation: conversation) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:metadata) do
      {
        model: 'gpt-4o-mini',
        citations: [
          { 'response_id' => 11, 'title' => 'Used FAQ', 'source' => 'https://example.com/used' },
          { 'response_id' => 22, 'title' => 'Other FAQ', 'source' => 'https://example.com/other' }
        ],
        generation_path: [{ 'tool' => 'search_documentation', 'arguments' => { 'query' => 'hi' } }]
      }
    end

    it 'persists the generation metadata' do
      generation = described_class.record!(
        message: message, assistant: assistant, reasoning: 'because', used_sources: [], metadata: metadata
      )

      aggregate_failures do
        expect(generation.reasoning).to eq('because')
        expect(generation.model).to eq('gpt-4o-mini')
        expect(generation.generation_path).to eq(metadata[:generation_path])
      end
    end

    it 'flags citations listed in used_sources as used' do
      generation = described_class.record!(
        message: message, assistant: assistant, reasoning: 'because', used_sources: [11], metadata: metadata
      )

      used = generation.citations.index_by { |citation| citation['response_id'] }
      aggregate_failures do
        expect(used[11]['used']).to be(true)
        expect(used[22]['used']).to be(false)
      end
    end
  end

  describe 'factory' do
    it 'creates a valid message generation' do
      expect(build(:captain_message_generation)).to be_valid
    end
  end
end
