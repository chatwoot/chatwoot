require 'rails_helper'

RSpec.describe Messages::ForwardedMessageBuilder do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let(:user) { create(:user, account: account) }

  # Create a message with email data
  let(:forwarded_message) do
    create(:message, conversation: conversation, account: account,
                     content_attributes: {
                       email: {
                         'from' => ['sender@example.com'],
                         'to' => ['recipient@example.com'],
                         'subject' => 'Test Subject',
                         'date' => '2025-04-29T14:29:07+05:30',
                         'html_content' => {
                           'full' => '<div>HTML content</div>',
                           'quoted' => 'HTML content',
                           'reply' => 'HTML content'
                         },
                         'text_content' => {
                           'full' => 'Text content',
                           'quoted' => 'Text content',
                           'reply' => 'Text content'
                         }
                       }
                     })
  end

  # Create a message with no email data
  let(:regular_message) { create(:message, conversation: conversation, account: account) }

  describe '#perform' do
    context 'when message_id is nil' do
      it 'returns an empty hash' do
        builder = described_class.new(nil)
        expect(builder.perform).to eq({})
      end
    end

    context 'when forwarded message is not found' do
      it 'returns basic attributes' do
        builder = described_class.new(999)
        expect(builder.perform).to eq(content_attributes: { forwarded_message_id: 999 })
      end
    end

    context 'when forwarded message has no email data' do
      it 'returns basic attributes' do
        builder = described_class.new(regular_message.id)
        expect(builder.perform).to eq(content_attributes: { forwarded_message_id: regular_message.id })
      end
    end

    context 'when forwarded message has email data' do
      it 'returns forwarded attributes' do
        builder = described_class.new(forwarded_message.id)
        result = builder.perform

        expect(result).to be_a(Hash)
        expect(result[:content_attributes]).to be_present
        expect(result[:content_attributes][:forwarded_message_id]).to eq(forwarded_message.id)
        expect(result[:content_attributes][:email]).to be_present
      end
    end
  end

  describe '#formatted_content' do
    context 'when forwarded message has no email data' do
      it 'returns original content' do
        builder = described_class.new(regular_message.id)
        expect(builder.formatted_content('Original')).to eq('Original')
      end
    end

    context 'when forwarded message has email data' do
      it 'returns formatted content with header and body' do
        builder = described_class.new(forwarded_message.id)
        result = builder.formatted_content('Original')

        expect(result).to include('Original')
        expect(result).to include('---------- Forwarded message ---------')
        expect(result).to include('From:')
        expect(result).to include('Date:')
        expect(result).to include('Subject: Test Subject')
        expect(result).to include('Text content') # Should include the text content
      end
    end
  end

  describe '#formatted_html_content' do
    context 'when forwarded message has no email data' do
      it 'returns original content' do
        builder = described_class.new(regular_message.id)
        expect(builder.formatted_html_content('Original')).to eq('Original')
      end
    end

    context 'when forwarded message has email data' do
      it 'returns formatted HTML content with header and body' do
        builder = described_class.new(forwarded_message.id)
        result = builder.formatted_html_content('**Original**')

        expect(result).to include('<b>Original</b>') # Markdown converted to HTML
        expect(result).to include('---------- Forwarded message ---------')
        expect(result).to include('From:')
        expect(result).to include('Date:')
        expect(result).to include('Subject: Test Subject')
        expect(result).to include('<div>HTML content</div>') # Should include the HTML content
      end
    end
  end

  describe '#forwarded_email_data' do
    context 'when forwarded message has no email data' do
      it 'returns empty hash' do
        builder = described_class.new(regular_message.id)
        expect(builder.forwarded_email_data('Original')).to eq({})
      end
    end

    context 'when forwarded message has email data' do
      it 'returns complete email data structure' do
        builder = described_class.new(forwarded_message.id)
        result = builder.forwarded_email_data('**Original**')

        expect(result).to be_a(Hash)
        expect(result['html_content']).to be_present
        expect(result['text_content']).to be_present

        # Check HTML content
        expect(result['html_content']['quoted']).to eq('Original') # Markdown stripped
        expect(result['html_content']['full']).to include('<b>Original</b>') # HTML formatted

        # Check text content
        expect(result['text_content']['quoted']).to eq('**Original**') # Original text preserved
        expect(result['text_content']['full']).to include('---------- Forwarded message ---------')
      end
    end

    context 'when handling multipart emails' do
      let(:multipart_message) do
        create(:message, conversation: conversation, account: account,
                         content_attributes: {
                           email: {
                             'from' => ['sender@example.com'],
                             'to' => ['recipient@example.com'],
                             'subject' => 'Multipart Test',
                             'date' => '2025-04-29T14:29:07+05:30',
                             'html_content' => {
                               'full' => '<div>HTML <b>formatted</b> content</div>'
                             },
                             'text_content' => {
                               'full' => 'Plain text content'
                             }
                           }
                         })
      end

      it 'preserves both HTML and text parts' do
        builder = described_class.new(multipart_message.id)
        result = builder.forwarded_email_data('New message')

        expect(result['html_content']['full']).to include('<div>HTML <b>formatted</b> content</div>')
        expect(result['text_content']['full']).to include('Plain text content')
      end
    end
  end

  describe '#convert_markdown_to_html' do
    it 'converts bold markdown to HTML' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:convert_markdown_to_html, '**Bold Text**')
      expect(result).to eq('<b>Bold Text</b>')
    end

    it 'converts italic markdown to HTML' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:convert_markdown_to_html, '*Italic Text*')
      expect(result).to eq('<i>Italic Text</i>')
    end

    it 'converts underscore italic markdown to HTML' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:convert_markdown_to_html, '_Italic Text_')
      expect(result).to eq('<i>Italic Text</i>')
    end

    it 'handles empty text' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:convert_markdown_to_html, '')
      expect(result).to eq('')
    end

    it 'handles nil text' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:convert_markdown_to_html, nil)
      expect(result).to eq('')
    end
  end

  describe '#strip_markdown' do
    it 'strips bold markdown' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:strip_markdown, '**Bold Text**')
      expect(result).to eq('Bold Text')
    end

    it 'strips italic markdown' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:strip_markdown, '*Italic Text*')
      expect(result).to eq('Italic Text')
    end

    it 'strips underscore italic markdown' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:strip_markdown, '_Italic Text_')
      expect(result).to eq('Italic Text')
    end

    it 'handles empty text' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:strip_markdown, '')
      expect(result).to eq('')
    end

    it 'handles nil text' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:strip_markdown, nil)
      expect(result).to eq('')
    end
  end

  describe '#extract_email' do
    it 'extracts email from format "Name <email@example.com>"' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:extract_email, 'John Doe <john@example.com>')
      expect(result).to eq('john@example.com')
    end

    it 'returns plain email as-is' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:extract_email, 'john@example.com')
      expect(result).to eq('john@example.com')
    end

    it 'handles empty string' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:extract_email, '')
      expect(result).to eq('')
    end

    it 'handles nil' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:extract_email, nil)
      expect(result).to eq('')
    end
  end

  describe '#parse_from_field' do
    it 'formats "Name <email@example.com>" correctly' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:parse_from_field, 'John Doe <john@example.com>')
      expect(result).to eq('John Doe <john@example.com>')
    end

    it 'handles plain email' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:parse_from_field, 'john@example.com')
      expect(result).to eq('john@example.com')
    end

    it 'handles extra spaces' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:parse_from_field, 'John Doe  <  john@example.com  >')
      expect(result).to eq('John Doe <john@example.com>')
    end

    it 'handles empty string' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:parse_from_field, '')
      expect(result).to eq('')
    end

    it 'handles nil' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:parse_from_field, nil)
      expect(result).to eq('')
    end
  end

  describe '#format_date_string' do
    it 'formats the date in a readable format' do
      builder = described_class.new(forwarded_message.id)
      # NOTE: We don't test the exact formatted output since it uses DateTime.now
      # which would be different for each test run
      result = builder.send(:format_date_string, '2025-04-29T14:29:07+05:30')
      expect(result).to be_a(String)
      expect(result).to match(/\w{3}, \w{3} \d+, \d{4} at \d+:\d+ [AP]M/)
    end

    it 'handles empty string' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:format_date_string, '')
      expect(result).to eq('')
    end

    it 'handles nil' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:format_date_string, nil)
      expect(result).to eq('')
    end

    it 'returns current date formatted regardless of input' do
      builder = described_class.new(forwarded_message.id)
      result = builder.send(:format_date_string, 'Invalid Date')

      expect(result).to match(/\w{3}, \w{3} \d+, \d{4} at \d+:\d+ [AP]M/)
    end
  end
end
