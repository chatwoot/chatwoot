require_relative '_lib'

describe RestClient::ParamsArray do

  describe '.new' do
    it 'accepts various types of containers' do
      as_array = [[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]]
      [
        [[:foo, 123], [:foo, 456], [:bar, 789], [:empty, nil]],
        [{foo: 123}, {foo: 456}, {bar: 789}, {empty: nil}],
        [{foo: 123}, {foo: 456}, {bar: 789}, {empty: nil}],
        [{foo: 123}, [:foo, 456], {bar: 789}, {empty: nil}],
        [{foo: 123}, [:foo, 456], {bar: 789}, [:empty]],
      ].each do |input|
        expect(RestClient::ParamsArray.new(input).to_a).to eq as_array
      end

      expect(RestClient::ParamsArray.new([]).to_a).to eq []
      expect(RestClient::ParamsArray.new([]).empty?).to eq true
    end

    it 'rejects various invalid input' do
      expect {
        RestClient::ParamsArray.new([[]])
      }.to raise_error(IndexError)

      expect {
        RestClient::ParamsArray.new([[1,2,3]])
      }.to raise_error(ArgumentError)

      expect {
        RestClient::ParamsArray.new([1,2,3])
      }.to raise_error(NoMethodError)
    end
  end
end
