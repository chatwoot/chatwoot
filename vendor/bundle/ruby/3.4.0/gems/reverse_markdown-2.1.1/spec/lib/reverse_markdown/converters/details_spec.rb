require 'spec_helper'

describe ReverseMarkdown::Converters::Details do
  let(:converter) { ReverseMarkdown::Converters::Details.new }

  context 'for standard markdown' do
    before { ReverseMarkdown.config.github_flavored = false }

    it 'handles details tags correctly' do
      node = node_for("<details>foo</details>")
      expect(converter.convert(node)).to include "foo"
    end
  end

  context 'for github_flavored markdown' do
    before { ReverseMarkdown.config.github_flavored = true }

    it 'handles details tags correctly' do
      node = node_for("<details>foo</details>")
      expect(converter.convert(node)).to include "#foo"
    end
  end
end