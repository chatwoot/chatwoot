require 'spec_helper'

describe ReverseMarkdown::Converters::Br do
  let(:converter) { ReverseMarkdown::Converters::Br.new }

  it 'just converts into two spaces and a newline' do
    expect(converter.convert(:anything)).to eq "  \n"
  end
end
