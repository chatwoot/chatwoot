require 'rails_helper'

RSpec.describe MarkdownSetextEscape do
  describe '.call' do
    it 'escapes the delimiter when an empty line sits directly above it' do
      content = "Answer\n\n\\\n--\n\nRegards"
      expect(described_class.call(content)).to eq("Answer\n\n\\\n\\--\n\nRegards")
    end

    it 'handles CRLF line endings' do
      content = "Answer\r\n\r\n\\\r\n--\r\n\r\nRegards"
      expect(described_class.call(content)).to eq("Answer\r\n\r\n\\\r\n\\--\r\n\r\nRegards")
    end

    it 'escapes equals underlines the same way' do
      expect(described_class.call("Answer\n\n\\\n==\n\nRegards")).to eq("Answer\n\n\\\n\\==\n\nRegards")
    end

    it 'escapes only the underline when several empty lines precede the delimiter' do
      content = "Answer\n\n\\\n\\\n--\n\nRegards"
      expect(described_class.call(content)).to eq("Answer\n\n\\\n\\\n\\--\n\nRegards")
    end

    it 'escapes a delimiter at the end of the content' do
      expect(described_class.call("Answer\n\n\\\n--")).to eq("Answer\n\n\\\n\\--")
    end

    it 'leaves a plain delimiter without a preceding empty line untouched' do
      content = "Answer\n\n--\n\nRegards"
      expect(described_class.call(content)).to eq(content)
    end

    it 'leaves hard breaks followed by regular text untouched' do
      content = "Thanks \\\nSivin | Chatwoot"
      expect(described_class.call(content)).to eq(content)
    end

    it 'leaves intentional setext headings untouched' do
      content = "Title\n---\n\nBody"
      expect(described_class.call(content)).to eq(content)
    end

    it 'leaves thematic breaks untouched' do
      content = "para\n\n---\n\npara2"
      expect(described_class.call(content)).to eq(content)
    end
  end
end
