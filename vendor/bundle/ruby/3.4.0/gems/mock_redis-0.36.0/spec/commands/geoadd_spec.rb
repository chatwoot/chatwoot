require 'spec_helper'

describe '#geoadd' do
  let(:key) { 'cities' }

  context 'with valid points' do
    let(:san_francisco) { [-122.5076404, 37.757815, 'SF'] }
    let(:los_angeles) { [-118.6919259, 34.0207305, 'LA'] }
    let(:expected_result) do
      [['LA', 1.364461589564902e+15], ['SF', 1.367859319053696e+15]]
    end

    before { @redises.geoadd(key, *san_francisco, *los_angeles) }

    after { @redises.zrem(key, %w[SF LA]) }

    it 'adds members to ZSET' do
      cities = @redises.zrange(key, 0, -1, with_scores: true)
      expect(cities).to be == expected_result
    end
  end

  context 'with invalud points' do
    context 'when number of arguments wrong' do
      let(:message) { "ERR wrong number of arguments for 'geoadd' command" }

      it 'raises Redis::CommandError' do
        expect { @redises.geoadd(key, 1, 1) }
          .to raise_error(Redis::CommandError, message)
      end
    end

    context 'when coordinates are not in allowed range' do
      let(:coords) { [181, 86] }
      let(:message) do
        formatted_coords = coords.map { |c| format('%<coords>.6f', coords: c) }
        "ERR invalid longitude,latitude pair #{formatted_coords.join(',')}"
      end

      after { @redises.zrem(key, 'SF') }

      it 'raises Redis::CommandError' do
        expect { @redises.geoadd(key, *coords, 'SF') }
          .to raise_error(Redis::CommandError, message)
      end
    end

    context 'when coordinates are not valid floats' do
      let(:coords) { ['x', 35] }
      let(:message) { 'ERR value is not a valid float' }

      it 'raises Redis::CommandError' do
        expect { @redises.geoadd key, *coords, 'SF' }
          .to raise_error(Redis::CommandError, message)
      end
    end
  end
end
