require 'spec_helper'

describe '#geohash' do
  let(:key) { 'cities' }

  context 'with existing key' do
    let(:san_francisco) { [-122.5076404, 37.757815, 'SF'] }
    let(:los_angeles) { [-118.6919259, 34.0207305, 'LA'] }

    before { @redises.geoadd(key, *san_francisco, *los_angeles) }

    after { @redises.zrem(key, %w[SF LA]) }

    context 'with existing points only' do
      let(:expected_result) do
        %w[9q8yu38ejp0 9q59e171je0]
      end

      it 'returns decoded coordinates pairs for each point' do
        results = @redises.geohash(key, %w[SF LA])
        expect(results).to be == expected_result
      end

      context 'with non-existing points only' do
        it 'returns array filled with nils' do
          results = @redises.geohash(key, %w[FF FA])
          expect(results).to be == [nil, nil]
        end
      end

      context 'with both existing and non-existing points' do
        let(:expected_result) do
          ['9q8yu38ejp0', nil]
        end

        it 'returns mixture of nil and coordinates pair' do
          results = @redises.geohash(key, %w[SF FA])
          expect(results).to be == expected_result
        end
      end
    end
  end

  context 'with non-existing key' do
    before { @redises.del(key) }

    it 'returns empty array' do
      results = @redises.geohash(key, %w[SF LA])
      expect(results).to be == [nil, nil]
    end
  end
end
