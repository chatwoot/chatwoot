require 'spec_helper'

describe ReverseMarkdown do

  let(:input)    { File.read('spec/assets/code.html') }
  let(:document) { Nokogiri::HTML(input) }
  subject { ReverseMarkdown.convert(input) }

  it { is_expected.to match /inline `code` block/ }
  it { is_expected.to match /\    var this\;\n    this\.is/ }
  it { is_expected.to match /block"\)\n    console/ }

  context "with github style code blocks" do
    subject { ReverseMarkdown.convert(input, github_flavored: true) }
    it { is_expected.to match /inline `code` block/ }
    it { is_expected.to match /```\nvar this\;\nthis/ }
    it { is_expected.to match /it is"\) ?\n```/ }
  end

  context "code with indentation" do
    subject { ReverseMarkdown.convert(input) }
    it { is_expected.to match(/^    tell application "Foo"\n/) }
    it { is_expected.to match(/^        beep\n/) }
    it { is_expected.to match(/^    end tell\n/) }
  end

end

