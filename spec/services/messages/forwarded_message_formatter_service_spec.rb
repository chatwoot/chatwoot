require 'rails_helper'

RSpec.describe Messages::ForwardedMessageFormatterService do
  describe '.convert_markdown_to_html' do
    it 'converts bold markdown to HTML' do
      formatted = described_class.convert_markdown_to_html('**Bold Text**')
      # Updated expectation to match CommonMarker output format
      expect(formatted).to include('<strong>Bold Text</strong>')
    end

    it 'converts italic markdown to HTML' do
      formatted = described_class.convert_markdown_to_html('*Italic Text*')
      expect(formatted).to include('<em>Italic Text</em>')
    end

    it 'converts underscore italic markdown to HTML' do
      formatted = described_class.convert_markdown_to_html('_Italic Text_')
      expect(formatted).to include('<em>Italic Text</em>')
    end

    it 'handles multiple markdown elements' do
      formatted = described_class.convert_markdown_to_html('**Bold** and _italic_')
      expect(formatted).to include('<strong>Bold</strong>')
      expect(formatted).to include('<em>italic</em>')
    end

    it 'handles empty text' do
      expect(described_class.convert_markdown_to_html('')).to eq('')
    end

    it 'handles nil text' do
      expect(described_class.convert_markdown_to_html(nil)).to eq('')
    end
  end

  describe '.strip_markdown' do
    it 'strips bold markdown' do
      stripped = described_class.strip_markdown('**Bold Text**')
      expect(stripped.strip).to eq('Bold Text')
    end

    it 'strips italic markdown' do
      stripped = described_class.strip_markdown('*Italic Text*')
      expect(stripped.strip).to eq('Italic Text')
    end

    it 'strips underscore italic markdown' do
      stripped = described_class.strip_markdown('_Italic Text_')
      expect(stripped.strip).to eq('Italic Text')
    end

    it 'handles multiple markdown elements' do
      stripped = described_class.strip_markdown('**Bold** and _italic_')
      # Updated expectation to handle trailing newline
      expect(stripped.strip).to eq('Bold and italic')
    end

    it 'handles empty text' do
      expect(described_class.strip_markdown('')).to eq('')
    end

    it 'handles nil text' do
      expect(described_class.strip_markdown(nil)).to eq('')
    end
  end

  describe '.extract_email' do
    it 'extracts email from format "Name <email@example.com>"' do
      extracted = described_class.extract_email('John Doe <john@example.com>')
      expect(extracted).to eq('john@example.com')
    end

    it 'returns plain email as-is' do
      extracted = described_class.extract_email('john@example.com')
      expect(extracted).to eq('john@example.com')
    end

    it 'handles empty string' do
      expect(described_class.extract_email('')).to eq('')
    end

    it 'handles nil' do
      expect(described_class.extract_email(nil)).to eq('')
    end
  end

  describe '.parse_from_field' do
    it 'extracts email from format "Name <email@example.com>"' do
      parsed = described_class.parse_from_field('John Doe <john@example.com>')
      expect(parsed).to eq('john@example.com')
    end

    it 'returns plain email as-is' do
      parsed = described_class.parse_from_field('john@example.com')
      expect(parsed).to eq('john@example.com')
    end

    it 'handles empty string' do
      expect(described_class.parse_from_field('')).to eq('')
    end

    it 'handles nil' do
      expect(described_class.parse_from_field(nil)).to eq('')
    end
  end

  describe '.format_date_string' do
    it 'formats the date in a readable format' do
      # NOTE: We don't test the exact formatted output since it uses DateTime.now
      # which would be different for each test run
      result = described_class.format_date_string('2025-04-29T14:29:07+05:30')
      expect(result).to match(/\w{3}, \w{3} \d+, \d{4} at \d+:\d+ [AP]M/)
    end

    it 'handles empty string' do
      expect(described_class.format_date_string('')).to eq('')
    end

    it 'handles nil' do
      expect(described_class.format_date_string(nil)).to eq('')
    end
  end

  describe '.format_plain_text_to_html' do
    it 'converts newlines to <br>' do
      result = described_class.format_plain_text_to_html("Line 1\nLine 2")
      expect(result).to eq('Line 1<br>Line 2')
    end

    it 'escapes HTML special characters' do
      result = described_class.format_plain_text_to_html('<script>alert("XSS")</script>')
      expect(result).to eq('&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;')
    end

    it 'handles empty string' do
      expect(described_class.format_plain_text_to_html('')).to eq('')
    end

    it 'handles nil' do
      expect(described_class.format_plain_text_to_html(nil)).to eq('')
    end
  end

  describe '.markdown_to_plain_text' do
    it 'converts markdown text to plain text' do
      plain_text = described_class.markdown_to_plain_text('**Bold** and _italic_ text')
      expect(plain_text.strip).to eq('Bold and italic text')
    end

    it 'handles empty string' do
      expect(described_class.markdown_to_plain_text('')).to eq('')
    end

    it 'handles nil' do
      expect(described_class.markdown_to_plain_text(nil)).to eq('')
    end
  end
end
