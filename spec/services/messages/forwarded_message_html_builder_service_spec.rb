require 'rails_helper'

RSpec.describe Messages::ForwardedMessageHtmlBuilderService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }

  let(:formatted_info) do
    {
      from: 'sender@example.com',
      date: 'Wed, Apr 29, 2025 at 2:29 PM',
      subject: 'Test Subject',
      to: 'recipient@example.com'
    }
  end

  let(:base_email_content) do
    {
      'html_content' => {
        'full' => '<div>HTML content</div>'
      },
      'text_content' => {
        'full' => 'Text content'
      }
    }
  end

  let(:forwarded_message) do
    create(:message, conversation: conversation, account: account,
                     content_attributes: { email: base_email_content })
  end

  let(:html_builder) { described_class.new(formatted_info, forwarded_message, base_email_content) }
  let(:empty_builder) { described_class.new({}, forwarded_message, {}) }

  describe '#html_wrapper' do
    it 'wraps content with proper HTML structure' do
      result = html_builder.html_wrapper('<p>Test content</p>')

      expect(result).to start_with('<div dir="ltr">')
      expect(result).to include('<p>Test content</p>')
      expect(result).to include('<br><br>')
      expect(result).to include('---------- Forwarded message ---------')
      expect(result).to end_with('</div>')
    end

    it 'includes header and body even when content is blank' do
      result = html_builder.html_wrapper('')

      expect(result).to start_with('<div dir="ltr">')
      expect(result).to include('---------- Forwarded message ---------')
      expect(result).to include('<br><br>')
      expect(result).to end_with('</div>')
    end
  end

  describe '#forwarded_header_html' do
    it 'formats header with all fields' do
      allow(Messages::ForwardedMessageFormatterService).to receive(:extract_email).and_return('sender@example.com')

      result = html_builder.forwarded_header_html

      expect(result).to include('gmail_quote_container')
      expect(result).to include('---------- Forwarded message ---------')
      expect(result).to include('From: &lt;<a href="mailto:sender@example.com">sender@example.com</a>&gt;')
      expect(result).to include('Date: Wed, Apr 29, 2025 at 2:29 PM')
      expect(result).to include('Subject: Test Subject')
      expect(result).to include('To: &lt;<a href="mailto:recipient@example.com">recipient@example.com</a>&gt;')

      expect(Messages::ForwardedMessageFormatterService).to have_received(:extract_email).with('sender@example.com')
    end

    it 'omits empty fields' do
      empty_info = { from: '', subject: 'Test Subject' }
      builder = described_class.new(empty_info, forwarded_message, base_email_content)

      result = builder.forwarded_header_html

      expect(result).to include('---------- Forwarded message ---------')
      expect(result).to include('Subject: Test Subject')
      expect(result).not_to include('From:')
      expect(result).not_to include('Date:')
      expect(result).not_to include('To:')
    end
  end

  describe '#forwarded_body_html' do
    it 'returns HTML content when available' do
      result = html_builder.forwarded_body_html

      expect(result).to eq('<div>HTML content</div>')
    end

    it 'converts text to HTML when HTML is not available' do
      text_only_content = { 'text_content' => { 'full' => 'Text only content' } }
      builder = described_class.new(formatted_info, forwarded_message, text_only_content)

      allow(Messages::ForwardedMessageFormatterService).to receive(:convert_markdown_to_html).and_return('<p>Converted HTML</p>')

      result = builder.forwarded_body_html

      expect(Messages::ForwardedMessageFormatterService).to have_received(:convert_markdown_to_html).with('Text only content')
      expect(result).to eq('<p>Converted HTML</p>')
    end

    it 'falls back to message content when no email data is available' do
      allow(forwarded_message).to receive(:content).and_return('Message content')

      empty_builder.forwarded_body_html

      expect(Messages::ForwardedMessageFormatterService).to receive(:convert_markdown_to_html).with('Message content')
      empty_builder.forwarded_body_html
    end
  end

  describe 'private methods' do
    describe '#build_email_html' do
      it 'formats email with HTML markup' do
        result = html_builder.send(:build_email_html, 'test@example.com')

        expect(result).to eq('From: &lt;<a href="mailto:test@example.com">test@example.com</a>&gt;<br>')
      end

      it 'returns nil for blank email' do
        expect(html_builder.send(:build_email_html, '')).to be_nil
        expect(html_builder.send(:build_email_html, nil)).to be_nil
      end
    end

    describe '#build_field_html' do
      it 'formats field with label and value' do
        result = html_builder.send(:build_field_html, 'Test', 'Value')

        expect(result).to eq('Test: Value<br>')
      end

      it 'returns nil for blank value' do
        expect(html_builder.send(:build_field_html, 'Test', '')).to be_nil
        expect(html_builder.send(:build_field_html, 'Test', nil)).to be_nil
      end
    end

    describe '#build_to_html' do
      it 'formats to field with HTML markup' do
        result = html_builder.send(:build_to_html, 'recipient@example.com')

        expect(result).to eq('To: &lt;<a href="mailto:recipient@example.com">recipient@example.com</a>&gt;<br>')
      end

      it 'returns nil for blank email' do
        expect(html_builder.send(:build_to_html, '')).to be_nil
        expect(html_builder.send(:build_to_html, nil)).to be_nil
      end
    end
  end
end
