require 'spec_helper'

describe ReverseMarkdown do

  let(:input)    { File.read('spec/assets/html_fragment.html') }
  let(:document) { Nokogiri::HTML(input) }
  subject { ReverseMarkdown.convert(input) }

  it { is_expected.to eq("naked text 1\n\nparagraph text\n\nnaked text 2") }
end

