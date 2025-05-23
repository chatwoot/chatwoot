require 'rails_helper'

RSpec.describe Messages::ForwardedMessageBuilderService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let(:user) { create(:user, account: account) }

  let(:base_email_content) do
    {
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
  end

  # Create a message with email data
  let(:forwarded_message) do
    create(:message, conversation: conversation, account: account,
                     content_attributes: { email: base_email_content })
  end

  # Create a message with multipart email data
  let(:multipart_message) do
    create(:message, conversation: conversation, account: account,
                     content_attributes: {
                       email: base_email_content.merge(
                         'html_content' => { 'full' => '<div>HTML <b>formatted</b> content</div>' },
                         'text_content' => { 'full' => 'Plain text content' }
                       )
                     })
  end

  # Create a message with email data and attachments
  let(:message_with_attachments) do
    message = create(:message, conversation: conversation, account: account,
                               content_attributes: {
                                 email: base_email_content.merge(
                                   'html_content' => { 'full' => '<div>Message with attachments</div>' },
                                   'text_content' => { 'full' => 'Message with attachments' }
                                 )
                               })

    # Add attachments to the message
    attachment1 = message.attachments.new(account_id: account.id, file_type: 'file')
    attachment1.file.attach(io: StringIO.new('test file content'), filename: 'test.txt', content_type: 'text/plain')
    attachment1.save!

    attachment2 = message.attachments.new(account_id: account.id, file_type: 'image')
    attachment2.file.attach(io: StringIO.new('fake image content'), filename: 'test.jpg', content_type: 'image/jpeg')
    attachment2.save!

    message
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
      it 'returns basic attributes with empty email structure' do
        builder = described_class.new(regular_message.id)
        result = builder.perform

        expect(result[:content_attributes][:forwarded_message_id]).to eq(regular_message.id)

        expect(result[:content_attributes][:email]).to be_present
        expect(result[:content_attributes][:email]).to have_key('date')
        expect(result[:content_attributes][:email]).to have_key('subject')
        expect(result[:content_attributes][:email]).to have_key('from')
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
    context 'when forwarded message is blank' do
      it 'returns original content' do
        builder = described_class.new(999) # Non-existent message ID
        expect(builder.formatted_content('Original')).to eq('Original')
      end
    end

    context 'when forwarded message has no email data' do
      it 'returns formatted content with basic information' do
        builder = described_class.new(regular_message.id)
        result = builder.formatted_content('Original')

        expect(result).to include('Original')
        expect(result).to include('---------- Forwarded message ---------')
      end
    end

    context 'when forwarded message has email data' do
      it 'returns formatted content with header and body' do
        builder = described_class.new(forwarded_message.id)
        result = builder.formatted_content('Original')

        expect(result).to include('Original')
        expect(result).to include('---------- Forwarded message ---------')
        expect(result).to include('Subject: Test Subject')
        expect(result).to include('Text content') # Should include the text content
      end
    end
  end

  describe '#forwarded_email_data' do
    context 'when forwarded message is blank' do
      it 'returns empty hash' do
        builder = described_class.new(999)
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

        expect(result['html_content']['full']).to include('Original')
        expect(result['text_content']['full']).to include('---------- Forwarded message ---------')
      end
    end

    context 'when handling multipart emails' do
      it 'preserves both HTML and text parts' do
        builder = described_class.new(multipart_message.id)
        result = builder.forwarded_email_data('New message')

        expect(result['html_content']['full']).to include('<div>HTML <b>formatted</b> content</div>')
        expect(result['text_content']['full']).to include('Plain text content')
      end
    end

    context 'when forwarding a message with attachments' do
      it 'includes attachments in the forwarded email data' do
        builder = described_class.new(message_with_attachments.id)
        result = builder.forwarded_email_data('Original content')

        expect(result['attachments']).to be_present
        expect(result['attachments'].length).to eq(2)
        expect(result['attachments'].pluck('file_type')).to match_array(%w[file image])
      end
    end

    context 'when forwarding a message without attachments' do
      it 'does not include attachments in the forwarded email data' do
        builder = described_class.new(forwarded_message.id)
        result = builder.forwarded_email_data('Original content')

        expect(result['attachments']).to be_nil
      end
    end
  end

  describe '#forwarded_attachments' do
    context 'with attachments' do
      it 'provides access to the forwarded message attachments' do
        builder = described_class.new(message_with_attachments.id)
        attachments = builder.forwarded_attachments

        expect(attachments).to be_present
        expect(attachments.length).to eq(2)
        expect(attachments.map(&:file_type)).to match_array(%w[file image])
        expect(attachments.first.file).to be_attached
      end
    end

    context 'without attachments' do
      it 'returns nil when getting forwarded attachments' do
        builder = described_class.new(forwarded_message.id)
        attachments = builder.forwarded_attachments

        expect(attachments).to be_nil
      end
    end
  end
end
