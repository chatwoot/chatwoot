require 'rails_helper'

RSpec.describe Chatwoot::ConfiguredOrigin do
  describe '.from_env' do
    it 'returns nil when the variable is unset or blank' do
      with_modified_env('TEST_ORIGIN' => nil) do
        expect(described_class.from_env('TEST_ORIGIN')).to be_nil
      end

      with_modified_env('TEST_ORIGIN' => ' ') do
        expect(described_class.from_env('TEST_ORIGIN')).to be_nil
      end
    end

    it 'returns a normalized HTTPS origin with its port' do
      with_modified_env('TEST_ORIGIN' => 'https://media.example.test:8443/') do
        origin = described_class.from_env('TEST_ORIGIN')

        expect(origin.to_s).to eq('https://media.example.test:8443')
        expect(origin.port).to eq(8443)
      end
    end

    it 'rejects non-origin URLs' do
      [
        'http://media.example.test',
        'https://user:password@media.example.test',
        'https://media.example.test/path',
        'https://media.example.test?query=1',
        'https://media.example.test#fragment',
        'https://media.example.test:70000'
      ].each do |value|
        with_modified_env('TEST_ORIGIN' => value) do
          expect { described_class.from_env('TEST_ORIGIN') }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
