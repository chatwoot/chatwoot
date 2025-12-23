require 'spec_helper'

describe '#scan' do
  subject { MockRedis::Database.new(self) }

  let(:count) { 10 }
  let(:match) { '*' }

  before do
    allow(subject).to receive_message_chain(:data, :keys).and_return(collection)
  end

  context 'when no keys are found' do
    let(:collection) { [] }

    it 'returns a 0 cursor and an empty collection' do
      expect(subject.scan(0, count: count, match: match)).to eq(['0', []])
    end
  end

  context 'when keys are found' do
    context 'when count is lower than collection size' do
      let(:collection) { Array.new(count * 2) { |i| "mock:key#{i}" } }
      let(:expected_first) { [count.to_s, collection[0...count]] }
      let(:expected_second) { ['0', collection[count..-1]] }

      it 'returns a the next cursor and the collection' do
        expect(subject.scan(0, count: count, match: match)).to eq(expected_first)
      end

      it 'returns the correct results of the next cursor' do
        expect(subject.scan(count, count: count, match: match)).to eq(expected_second)
      end
    end

    context 'when count is greater or equal than collection size' do
      let(:collection) { Array.new(count) { |i| "mock:key#{i}" } }
      let(:expected) { ['0', collection] }

      it 'returns a 0 cursor and the collection' do
        expect(subject.scan(0, count: count, match: match)).to eq(expected)
      end
    end

    context 'when cursor is greater than collection size' do
      let(:collection) { Array.new(count) { |i| "mock:key#{i}" } }
      let(:expected) { ['0', []] }

      it 'returns a 0 cursor and empty collection' do
        expect(subject.scan(20, count: count, match: match)).to eq(expected)
      end
    end

    context 'when giving a custom match filter' do
      let(:match) { 'mock:key*' }
      let(:collection) { %w[mock:key mock:key2 mock:otherkey] }
      let(:expected) { ['0', %w[mock:key mock:key2]] }

      it 'returns a 0 cursor and the filtered collection' do
        expect(subject.scan(0, count: count, match: match)).to eq(expected)
      end
    end
  end
end
