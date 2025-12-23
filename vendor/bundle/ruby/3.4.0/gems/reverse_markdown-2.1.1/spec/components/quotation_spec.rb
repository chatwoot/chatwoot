require 'spec_helper'

describe ReverseMarkdown do
  let(:input)    { File.read('spec/assets/quotation.html') }
  let(:document) { Nokogiri::HTML(input) }
  subject { ReverseMarkdown.convert(input) }

  it { is_expected.to match /^    Block of code$/ }
  it { is_expected.to include "\n> First quoted paragraph\n> \n> Second quoted paragraph" }
end
