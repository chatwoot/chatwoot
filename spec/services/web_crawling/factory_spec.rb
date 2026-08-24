require 'rails_helper'

RSpec.describe WebCrawling::Factory do
  describe '.build' do
    it 'returns the native spider by default' do
      expect(described_class.build).to be_a(WebCrawling::Native::Spider)
    end

    it 'rejects unsupported providers' do
      expect { described_class.build(provider: :unsupported) }.to raise_error(KeyError)
    end
  end
end
