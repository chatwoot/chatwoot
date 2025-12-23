require 'spec_helper'

describe ReverseMarkdown::Converters::Text do

  let(:converter) { ReverseMarkdown::Converters::Text.new }

  it 'treats newline within text as a single whitespace' do
    input = node_for("<p>foo\nbar</p>")
    result = converter.convert(input)
    expect(result).to eq 'foo bar'
  end

  it 'handles windows-style \r\n correctly' do
    input = node_for("<p>foo \r\n\r\n bar</p>")
    result = converter.convert(input)
    expect(result).to eq 'foo bar'
  end

  it 'removes leading newlines' do
    input = node_for("<p>\n\nfoo bar</p>")
    result = converter.convert(input)
    expect(result).to eq 'foo bar'
  end

  it 'removes trailing newlines' do
    input = node_for("<p>foo bar\n\n</p>")
    result = converter.convert(input)
    expect(result).to eq 'foo bar'
  end

  it 'keeps nbsps' do
    input = node_for("<p>foo\u00A0bar \u00A0</p>")
    result = converter.convert(input)
    expect(result).to eq "foo&nbsp;bar &nbsp;"
  end

  it 'keeps escaped HTML-ish characters' do
    input = node_for("<p>&lt;foo&gt;</p>")
    result = converter.convert(input)
    expect(result).to eq '\<foo\>'
  end

  context 'within backticks' do
    it "preserves single underscores" do
      input = node_for("<p>`foo_bar`</p>")
      result = converter.convert(input)
      expect(result).to eq '`foo_bar`'
    end

    it "preserves multiple underscores" do
      input = node_for("<p>`foo_bar __example__`</p>")
      result = converter.convert(input)
      expect(result).to eq '`foo_bar __example__`'
    end

    it "preserves single asterisks" do
      input = node_for("<p>`def foo *args`</p>")
      result = converter.convert(input)
      expect(result).to eq '`def foo *args`'
    end

    it "preserves multiple asterisks" do
      input = node_for("<p>`def foo 2***3`</p>")
      result = converter.convert(input)
      expect(result).to eq '`def foo 2***3`'
    end
  end
end
