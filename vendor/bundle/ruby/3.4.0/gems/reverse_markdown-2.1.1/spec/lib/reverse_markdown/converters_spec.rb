require 'spec_helper'

describe ReverseMarkdown::Converters do
  before { ReverseMarkdown.config.unknown_tags = :raise }
  let(:converters) { ReverseMarkdown::Converters }

  describe '.register and .unregister' do
    it 'adds a converter mapping to the list' do
      expect { converters.lookup(:foo) }.to raise_error ReverseMarkdown::UnknownTagError

      converters.register :foo, :foobar
      expect(converters.lookup(:foo)).to eq :foobar

      converters.unregister :foo
      expect { converters.lookup(:foo) }.to raise_error ReverseMarkdown::UnknownTagError
    end
  end

end
