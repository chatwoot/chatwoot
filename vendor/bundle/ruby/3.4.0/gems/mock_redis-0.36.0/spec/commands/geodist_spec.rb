require 'spec_helper'

shared_examples 'a distance calculator' do
  it 'returns distance between two points in specified unit' do
    dist = @redises.geodist(key, 'SF', 'LA', unit)
    expect(dist).to be == expected_result
  end
end

describe '#geodist' do
  let(:key) { 'cities' }

  context 'with existing key' do
    let(:san_francisco) { [-122.5076404, 37.757815, 'SF'] }
    let(:los_angeles) { [-118.6919259, 34.0207305, 'LA'] }

    before { @redises.geoadd(key, *san_francisco, *los_angeles) }

    after { @redises.zrem(key, %w[SF LA]) }

    context 'with existing points only' do
      context 'using m as unit' do
        let(:unit) { 'm' }
        let(:expected_result) { '539327.9659' }

        it 'returns distance between two points in meters' do
          dist = @redises.geodist(key, 'SF', 'LA')
          expect(dist).to be == expected_result
        end

        it_behaves_like 'a distance calculator'
      end

      context 'using km as unit' do
        let(:unit) { 'km' }
        let(:expected_result) { '539.3280' }

        it_behaves_like 'a distance calculator'
      end

      context 'using ft as unit' do
        let(:unit) { 'ft' }
        let(:expected_result) { '1769448.7069' }

        it_behaves_like 'a distance calculator'
      end

      context 'using mi as unit' do
        let(:unit) { 'mi' }
        let(:expected_result) { '335.1237' }

        it_behaves_like 'a distance calculator'
      end

      context 'with non-existing points only' do
        it 'returns nil' do
          dist = @redises.geodist(key, 'FF', 'FA')
          expect(dist).to be_nil
        end
      end

      context 'with both existing and non-existing points' do
        it 'returns nil' do
          dist = @redises.geodist(key, 'SF', 'FA')
          expect(dist).to be_nil
        end
      end
    end
  end

  context 'with non-existing key' do
    it 'returns empty string' do
      dist = @redises.geodist(key, 'SF', 'LA')
      expect(dist).to be_nil
    end
  end

  context 'with wrong number of arguments' do
    let(:list) { [key, 'SF', 'LA', 'm', 'smth'] }

    context 'with less than 3 arguments' do
      [1, 2].each do |count|
        context "with #{count} arguments" do
          it 'raises an error' do
            args = list.slice(0, count)
            expect { @redises.geodist(*args) }
              .to raise_error(
                ArgumentError,
                /wrong number of arguments \((given\s)?#{count}(,\sexpected\s|\sfor\s)3?\.\.4\)$/
              )
          end
        end
      end
    end

    context 'with more than 3 arguments' do
      let(:message) { 'ERR syntax error' }

      it 'raises an error' do
        args = list.slice(0, 5)
        expect { @redises.geodist(*args) }
          .to raise_error(
            ArgumentError,
            /wrong number of arguments \((given\s)?5(,\sexpected\s|\sfor\s)3?\.\.4\)$/
          )
      end
    end
  end

  context 'with wrong unit' do
    let(:message) { 'ERR unsupported unit provided. please use m, km, ft, mi' }

    it 'raises an error' do
      expect { @redises.geodist(key, 'SF', 'LA', 'a') }
        .to raise_error(Redis::CommandError, message)
    end
  end
end
