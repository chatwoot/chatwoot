require 'rails_helper'

describe Digitaltolk::Openai::HtmlTranslation::BatchByContentLength do
  subject { described_class.perform(chunk_messages) }

  describe 'perform' do
    context 'when the total length of messages is less than the limit' do
      let(:chunk_messages) { ['Short message 1', 'Short message 2'] }

      it 'returns a single batch with all messages' do
        expect(subject).to eq([chunk_messages])
      end
    end

    context 'when the total length of messages exceeds the limit' do
      let(:chunk_messages) { ['a' * 300, 'b' * 200, 'c' * 200] }

      it 'splits messages into batches based on the character limit' do
        expect(subject.size).to eq(2)
        expect(subject[0].size).to eq(2)
        expect(subject[1].size).to eq(1)
      end
    end

    context 'when 1 message exceeds the limit' do
      let(:chunk_messages) { ['start', 'a' * 500, 'b' * 200, 'c' * 300, 'a'] }

      it 'creates a batch for the long message and another for the rest' do
        expect(subject.length).to eq(4)
        expect(subject[0].size).to eq(1)
        expect(subject[1].size).to eq(1)
        expect(subject[2].size).to eq(2)
        expect(subject[3].size).to eq(1)
      end
    end
  end
end
