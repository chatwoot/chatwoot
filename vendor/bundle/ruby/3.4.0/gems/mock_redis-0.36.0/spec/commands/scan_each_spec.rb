require 'spec_helper'

describe '#scan_each' do
  subject { MockRedis::Database.new(self) }

  let(:match) { '*' }

  before do
    allow(subject).to receive_message_chain(:data, :keys).and_return(collection)
  end

  context 'when no keys are found' do
    let(:collection) { [] }

    it 'does not iterate over any elements' do
      expect(subject.scan_each.to_a).to be_empty
    end
  end

  context 'when keys are found' do
    context 'when no match filter is supplied' do
      let(:collection) { Array.new(20) { |i| "mock:key#{i}" } }

      it 'iterates over each item in the collection' do
        expect(subject.scan_each.to_a).to match_array(collection)
      end
    end

    context 'when giving a custom match filter' do
      let(:match) { 'mock:key*' }
      let(:collection) { %w[mock:key mock:key2 mock:otherkey] }
      let(:expected) { %w[mock:key mock:key2] }

      it 'iterates over each item in the filtered collection' do
        expect(subject.scan_each(match: match).to_a).to match_array(expected)
      end
    end
  end
end
