require 'rails_helper'

RSpec.describe Messages::ForwardedMessageContentBuilderService do
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

  let(:html_only_message) do
    create(:message, conversation: conversation, account: account,
                     content_attributes: {
                       email: {
                         'html_content' => { 'full' => '<div>HTML only content</div>' },
                         'text_content' => {}
                       }
                     })
  end

  let(:content_builder) { described_class.new(formatted_info, forwarded_message, base_email_content) }
  let(:html_only_builder) { described_class.new(formatted_info, html_only_message, html_only_message.content_attributes[:email]) }
  let(:empty_builder) { described_class.new(formatted_info, forwarded_message, {}) }

  describe '#forwarded_header_text' do
    it 'returns a formatted header with all information' do
      header = content_builder.forwarded_header_text

      expect(header).to include('---------- Forwarded message ---------')
      expect(header).to include('From: sender@example.com')
      expect(header).to include('Date: Wed, Apr 29, 2025 at 2:29 PM')
      expect(header).to include('Subject: Test Subject')
      expect(header).to include('To: <recipient@example.com>')
    end

    it 'returns a formatted header without missing fields' do
      empty_info = { from: '', date: '', subject: '', to: '' }
      builder = described_class.new(empty_info, forwarded_message, base_email_content)

      expect(builder.forwarded_header_text).to include('---------- Forwarded message ---------')
      expect(builder.forwarded_header_text).not_to include('From: ')
      expect(builder.forwarded_header_text).not_to include('Date: ')
      expect(builder.forwarded_header_text).not_to include('Subject: ')
      expect(builder.forwarded_header_text).not_to include('To: ')
    end

    it 'handles partial information' do
      partial_info = { from: 'sender@example.com', subject: 'Test Subject' }
      builder = described_class.new(partial_info, forwarded_message, base_email_content)
      header = builder.forwarded_header_text

      expect(header).to include('From: sender@example.com')
      expect(header).to include('Subject: Test Subject')
      expect(header).not_to include('Date:')
      expect(header).not_to include('To:')
    end
  end

  describe '#forwarded_body_text' do
    it 'returns text content when available' do
      expect(content_builder.forwarded_body_text).to eq('Text content')
    end

    it 'returns sanitized HTML content when only HTML is available' do
      expect(html_only_builder.forwarded_body_text).to include('HTML only content')
    end

    it 'returns message content when no email data is available' do
      expect(empty_builder.forwarded_body_text).to eq(forwarded_message.content.to_s)
    end
  end

  describe '#formatted_content' do
    it 'returns original content concatenated with header and body' do
      result = content_builder.formatted_content('Original message')

      expect(result).to start_with('Original message')
      expect(result).to include('---------- Forwarded message ---------')
      expect(result).to include('Text content')
    end

    it 'returns just the original content when forwarded message is blank' do
      builder = described_class.new(formatted_info, nil, base_email_content)
      expect(builder.formatted_content('Original message')).to eq('Original message')
    end

    it 'handles empty original content' do
      result = content_builder.formatted_content('')

      expect(result).to include('---------- Forwarded message ---------')
      expect(result).to include('Text content')
    end
  end

  describe '#formatted_html_content' do
    it 'converts markdown in original content to HTML' do
      html_builder = instance_double(Messages::ForwardedMessageHtmlBuilderService)
      allow(Messages::ForwardedMessageHtmlBuilderService).to receive(:new)
        .with(formatted_info, forwarded_message, base_email_content)
        .and_return(html_builder)

      allow(Messages::ForwardedMessageFormatterService).to receive(:convert_markdown_to_html)
        .with('**Original** message')
        .and_return('<p>Converted HTML</p>')

      allow(html_builder).to receive(:html_wrapper)
        .with('<p>Converted HTML</p>')
        .and_return('<div>Wrapped content</div>')

      result = content_builder.formatted_html_content('**Original** message')

      expect(Messages::ForwardedMessageFormatterService).to have_received(:convert_markdown_to_html)
        .with('**Original** message')
      expect(result).to eq('<div>Wrapped content</div>')
    end

    it 'returns original content when forwarded message is blank' do
      builder = described_class.new(formatted_info, nil, base_email_content)
      expect(builder.formatted_html_content('Original message')).to eq('Original message')
    end
  end
end
