require 'spec_helper'

describe '#geopos' do
  let(:key) { 'cities' }

  context 'with existing key' do
    let(:san_francisco) { [-122.5076404, 37.757815, 'SF'] }
    let(:los_angeles) { [-118.6919259, 34.0207305, 'LA'] }

    before { @redises.geoadd(key, *san_francisco, *los_angeles) }

    after { @redises.zrem(key, %w[SF LA]) }

    context 'with existing points only' do
      let(:expected_result) do
        [
          %w[-122.5076410174369812 37.75781598995183685],
          %w[-118.69192510843276978 34.020729570911179]
        ]
      end

      it 'returns decoded coordinates pairs for each point' do
        coords = @redises.geopos(key, %w[SF LA])
        expect(coords).to be == expected_result
      end

      context 'with non-existing points only' do
        it 'returns array filled with nils' do
          coords = @redises.geopos(key, %w[FF FA])
          expect(coords).to be == [nil, nil]
        end
      end

      context 'with both existing and non-existing points' do
        let(:expected_result) do
          [%w[-122.5076410174369812 37.75781598995183685], nil]
        end

        it 'returns mixture of nil and coordinates pair' do
          coords = @redises.geopos(key, %w[SF FA])
          expect(coords).to be == expected_result
        end
      end
    end
  end

  context 'with non-existing key' do
    before { @redises.del(key) }

    it 'returns empty array' do
      coords = @redises.geopos(key, %w[SF LA])
      expect(coords).to be == [nil, nil]
    end
  end
end
