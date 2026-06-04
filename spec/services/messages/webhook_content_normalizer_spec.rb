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
  end
end
