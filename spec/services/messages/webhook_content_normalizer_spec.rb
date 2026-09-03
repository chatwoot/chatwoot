require 'rails_helper'

RSpec.describe Messages::WebhookContentNormalizer do
  describe '.normalize' do
    it 'returns nil unchanged' do
      expect(described_class.normalize(nil)).to be_nil
    end

    it 'returns blank string unchanged' do
      expect(described_class.normalize('')).to eq('')
    end

    it 'strips trailing newlines added by TipTap/ProseMirror' do
      expect(described_class.normalize("hello\n\n\n")).to eq('hello')
    end

    it 'preserves intentional trailing spaces' do
      expect(described_class.normalize("hello   \n\n")).to eq('hello   ')
    end

    it 'replaces CommonMark hard line breaks (backslash-newline) with plain newlines' do
      expect(described_class.normalize("hello\\\nworld")).to eq("hello\nworld")
    end

    it 'replaces CommonMark hard line breaks with CRLF with plain newlines' do
      expect(described_class.normalize("hello\\\r\nworld")).to eq("hello\nworld")
    end

    it 'preserves intentional internal newlines' do
      expect(described_class.normalize("line one\nline two")).to eq("line one\nline two")
    end

    it 'strips trailing CRLF newlines without leaving dangling carriage returns' do
      expect(described_class.normalize("hello\r\n\r\n")).to eq('hello')
    end

    it 'handles both hard line breaks and trailing newlines together' do
      expect(described_class.normalize("hello\\\nworld\n\n\n")).to eq("hello\nworld")
    end

    it 'unescapes the signature delimiter the editor escapes below an empty line' do
      expect(described_class.normalize("hey\n\n\\\n\\--\n\nThanks")).to eq("hey\n\n\n--\n\nThanks")
    end

    it 'unescapes an equals underline the same way' do
      expect(described_class.normalize("a\n\n\\\n\\==")).to eq("a\n\n\n==")
    end

    it 'unescapes a lone dash underline' do
      expect(described_class.normalize("a\\\n\\-")).to eq("a\n-")
    end

    it 'keeps backslashes that are not underline escapes' do
      expect(described_class.normalize('path C:\\temp and a \\- dash')).to eq('path C:\\temp and a \\- dash')
    end

    it 'preserves a literal escaped delimiter inside a fenced code block' do
      expect(described_class.normalize("```\n\\--\n```")).to eq("```\n\\--\n```")
    end

    it 'preserves trailing line-continuation backslashes inside a fenced code block' do
      expect(described_class.normalize("```c\n#define X \\\nint y;\n```")).to eq("```c\n#define X \\\nint y;\n```")
    end

    it 'normalizes the text around a fenced code block but not inside it' do
      expect(described_class.normalize("a\\\nb\n~~~\n\\==\n~~~\nc\\\nd")).to eq("a\nb\n~~~\n\\==\n~~~\nc\nd")
    end

    it 'keeps an unclosed fence untouched to the end of the message' do
      expect(described_class.normalize("```\n\\--")).to eq("```\n\\--")
    end
  end
end
