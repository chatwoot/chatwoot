require 'rails_helper'

RSpec.describe Messages::ForwardedMessageDataHandlerService do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, account: account) }
  let(:email_inbox) { create(:inbox, channel: email_channel, account: account) }
  let(:conversation) { create(:conversation, inbox: email_inbox, account: account) }
  let(:regular_inbox) { create(:inbox, account: account) }
  let(:regular_conversation) { create(:conversation, inbox: regular_inbox, account: account) }

  let(:base_email_content) do
    {
      'from' => ['John Doe <sender@example.com>'],
      'to' => ['recipient@example.com'],
      'subject' => 'Test Subject',
      'date' => '2025-04-29T14:29:07+05:30'
    }
  end

  # Message with email data and from an email inbox
  let(:email_message) do
    create(:message, conversation: conversation, account: account,
                     content_attributes: { email: base_email_content })
  end

  # Message with email data but from a regular inbox
  let(:regular_message) do
    create(:message, conversation: regular_conversation, account: account,
                     content_attributes: { email: base_email_content })
  end

  # Message with no email data
  let(:message_no_email) { create(:message, conversation: conversation, account: account) }

  describe '#prepare_email_data' do
    it 'returns empty hash structure when email_data is nil' do
      handler = described_class.new(message_no_email, nil)
      result = handler.prepare_email_data

      expect(result).to be_a(Hash)
      expect(result['html_content']).to eq({})
      expect(result['text_content']).to eq({})
      expect(result).to have_key('date')
      expect(result).to have_key('subject')
    end

    it 'preserves existing email data and adds required fields' do
      handler = described_class.new(email_message, base_email_content)
      result = handler.prepare_email_data

      expect(result).to be_a(Hash)
      expect(result['html_content']).to eq({})
      expect(result['text_content']).to eq({})
      expect(result['from']).to be_present
      expect(result['to']).to eq(['recipient@example.com'])
      expect(result['subject']).to eq('Test Subject')
      expect(result['date']).to eq('2025-04-29T14:29:07+05:30')
    end

    it 'adds to_emails from params if provided' do
      handler = described_class.new(email_message, base_email_content, { to_emails: 'new@example.com' })
      result = handler.prepare_email_data

      expect(result['to']).to eq(['new@example.com'])
    end

    it 'overwrites from field with inbox email' do
      handler = described_class.new(email_message, base_email_content)
      allow(handler).to receive(:email_from_inbox).and_return('inbox@example.com')

      result = handler.prepare_email_data

      expect(result['from']).to eq(['inbox@example.com'])
    end
  end

  describe '#formatted_info' do
    it 'returns hash with properly formatted fields' do
      allow(Messages::ForwardedMessageFormatterService).to receive(:format_date_string).and_return('Formatted Date')

      handler = described_class.new(email_message, base_email_content)
      result = handler.formatted_info

      expect(result[:from]).to be_present
      expect(result[:date]).to eq('Formatted Date')
      expect(result[:subject]).to eq('Test Subject')
      expect(result[:to]).to eq('recipient@example.com')

      expect(Messages::ForwardedMessageFormatterService).to have_received(:format_date_string).with('2025-04-29T14:29:07+05:30')
    end

    it 'works with missing email data' do
      # Create instance first, then stub its methods
      message_without_email = build(:message)
      handler = described_class.new(message_without_email, nil)

      # Stub the methods on the specific instance
      allow(handler).to receive(:email_from_data).and_return(nil)
      allow(handler).to receive(:email_from_inbox).and_return(nil)

      # For email_date, we should expect it to use Time.zone.now.to_s when email_data is nil
      # So we should mock the format_date_string to return a predictable value
      allow(Messages::ForwardedMessageFormatterService).to receive(:format_date_string).with(kind_of(String)).and_return('Fri, May 2, 2025 at 12:33 PM') # rubocop:disable Layout/LineLength

      result = handler.formatted_info

      expect(result[:from]).to eq('')
      expect(result[:date]).to eq('Fri, May 2, 2025 at 12:33 PM')
      expect(result[:subject]).to eq('No Subject')
      expect(result[:to]).to eq('')
    end
  end

  context 'when private methods are called' do
    describe '#inbox_email' do
      it 'returns email from data when available' do
        handler = described_class.new(email_message, base_email_content)
        allow(handler).to receive(:email_from_data).and_return('from_data@example.com')
        allow(handler).to receive(:email_from_inbox).and_return('from_inbox@example.com')

        result = handler.send(:inbox_email)

        expect(result).to eq('from_data@example.com')
      end

      it 'returns email from inbox when email data is not available' do
        handler = described_class.new(email_message, {})
        allow(handler).to receive(:email_from_data).and_return(nil)
        allow(handler).to receive(:email_from_inbox).and_return('from_inbox@example.com')

        result = handler.send(:inbox_email)

        expect(result).to eq('from_inbox@example.com')
      end
    end

    describe '#email_from_data' do
      it 'parses email address from from field' do
        handler = described_class.new(email_message, base_email_content)
        allow(Messages::ForwardedMessageFormatterService).to receive(:parse_from_field).and_return('parsed@example.com')

        result = handler.send(:email_from_data)

        expect(Messages::ForwardedMessageFormatterService).to have_received(:parse_from_field).with('John Doe <sender@example.com>')
        expect(result).to eq('parsed@example.com')
      end

      it 'returns nil when from field is not available' do
        handler = described_class.new(email_message, {})
        result = handler.send(:email_from_data)

        expect(result).to be_nil
      end
    end

    describe '#subject' do
      it 'returns subject from email data when available' do
        handler = described_class.new(email_message, base_email_content)
        result = handler.send(:subject)

        expect(result).to eq('Test Subject')
      end

      it 'returns subject from conversation when available' do
        allow(conversation).to receive(:additional_attributes).and_return({ 'subject' => 'Conversation Subject' })
        handler = described_class.new(email_message, {})
        result = handler.send(:subject)

        expect(result).to eq('Conversation Subject')
      end

      it 'returns "No Subject" when no subject is available' do
        handler = described_class.new(message_no_email, nil)
        result = handler.send(:subject)

        expect(result).to eq('No Subject')
      end
    end
  end
end
