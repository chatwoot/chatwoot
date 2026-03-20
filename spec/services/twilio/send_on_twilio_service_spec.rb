require 'rails_helper'

describe Twilio::SendOnTwilioService do
  subject(:outgoing_message_service) { described_class.new(message: message) }

  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:messages_double) { double }
  let(:message_record_double) { double }

  let!(:account) { create(:account) }
  let!(:twilio_sms) { create(:channel_twilio_sms, account: account) }
  let!(:twilio_inbox) { create(:inbox, channel: twilio_sms, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: twilio_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: twilio_inbox, contact_inbox: contact_inbox) }

  before do
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:messages).and_return(messages_double)
  end

  describe '#perform' do
    let!(:widget_inbox) { create(:inbox, account: account) }
    let!(:twilio_whatsapp) { create(:channel_twilio_sms, medium: :whatsapp, account: account) }
    let!(:twilio_whatsapp_inbox) { create(:inbox, channel: twilio_whatsapp, account: account) }

    context 'without reply' do
      it 'if message is private' do
        message = create(:message, message_type: 'outgoing', private: true, inbox: twilio_inbox, account: account)
        described_class.new(message: message).perform
        expect(twilio_client).not_to have_received(:messages)
        expect(message.reload.source_id).to be_nil
      end

      it 'if inbox channel is not twilio' do
        message = create(:message, message_type: 'outgoing', inbox: widget_inbox, account: account)
        expect { described_class.new(message: message).perform }.to raise_error 'Invalid channel service was called'
        expect(twilio_client).not_to have_received(:messages)
      end

      it 'if message is not outgoing' do
        message = create(:message, message_type: 'incoming', inbox: twilio_inbox, account: account)
        described_class.new(message: message).perform
        expect(twilio_client).not_to have_received(:messages)
        expect(message.reload.source_id).to be_nil
      end

      it 'if message has an source id' do
        message = create(:message, message_type: 'outgoing', inbox: twilio_inbox, account: account, source_id: SecureRandom.uuid)
        described_class.new(message: message).perform
        expect(twilio_client).not_to have_received(:messages)
      end
    end

    context 'with reply' do
      it 'if message is sent from chatwoot and is outgoing' do
        allow(messages_double).to receive(:create).and_return(message_record_double)
        allow(message_record_double).to receive(:sid).and_return('1234')

        outgoing_message = create(
          :message, message_type: 'outgoing', inbox: twilio_inbox, account: account, conversation: conversation
        )
        described_class.new(message: outgoing_message).perform

        expect(outgoing_message.reload.source_id).to eq('1234')
      end
    end

    it 'if outgoing message has attachment and is for whatsapp' do
      # check for message attachment url
      allow(messages_double).to receive(:create).with(hash_including(media_url: [anything])).and_return(message_record_double)
      allow(message_record_double).to receive(:sid).and_return('1234')

      message = build(
        :message, message_type: 'outgoing', inbox: twilio_whatsapp_inbox, account: account, conversation: conversation
      )
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      message.save!

      described_class.new(message: message).perform
      expect(messages_double).to have_received(:create)
    end

    it 'if outgoing message has attachment and is for sms' do
      # check for message attachment url
      allow(messages_double).to receive(:create).with(hash_including(media_url: [anything])).and_return(message_record_double)
      allow(message_record_double).to receive(:sid).and_return('1234')

      message = build(
        :message, message_type: 'outgoing', inbox: twilio_inbox, account: account, conversation: conversation
      )
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      message.save!

      described_class.new(message: message).perform
      expect(messages_double).to have_received(:create)
    end

    it 'if message is sent from chatwoot fails' do
      allow(messages_double).to receive(:create).and_raise(Twilio::REST::TwilioError)

      outgoing_message = create(
        :message, message_type: 'outgoing', inbox: twilio_inbox, account: account, conversation: conversation
      )
      described_class.new(message: outgoing_message).perform
      expect(outgoing_message.reload.status).to eq('failed')
    end
  end

  describe '#send_csat_template_message' do
    let(:test_message) { create(:message, message_type: 'outgoing', inbox: twilio_inbox, account: account, conversation: conversation) }
    let(:service) { described_class.new(message: test_message) }
    let(:mock_twilio_message) { instance_double(Twilio::REST::Api::V2010::AccountContext::MessageInstance, sid: 'SM123456789') }

    # Test parameters defined using let statements
    let(:test_params) do
      {
        phone_number: '+1234567890',
        content_sid: 'HX123456789',
        content_variables: { '1' => 'conversation-uuid-123' }
      }
    end

    before do
      allow(twilio_sms).to receive(:send_message_from).and_return({ from: '+0987654321' })
      allow(twilio_sms).to receive(:respond_to?).and_return(true)
      allow(twilio_sms).to receive(:twilio_delivery_status_index_url).and_return('http://localhost:3000/twilio/delivery_status')
    end

    context 'when template message is sent successfully' do
      before do
        allow(messages_double).to receive(:create).and_return(mock_twilio_message)
      end

      it 'sends template message with correct parameters' do
        expected_params = {
          to: test_params[:phone_number],
          content_sid: test_params[:content_sid],
          content_variables: test_params[:content_variables].to_json,
          status_callback: 'http://localhost:3000/twilio/delivery_status',
          from: '+0987654321'
        }

        result = service.send_csat_template_message(**test_params)

        expect(messages_double).to have_received(:create).with(expected_params)
        expect(result).to eq({ success: true, message_id: 'SM123456789' })
      end

      it 'sends template message without content variables when empty' do
        expected_params = {
          to: test_params[:phone_number],
          content_sid: test_params[:content_sid],
          status_callback: 'http://localhost:3000/twilio/delivery_status',
          from: '+0987654321'
        }

        result = service.send_csat_template_message(
          phone_number: test_params[:phone_number],
          content_sid: test_params[:content_sid]
        )

        expect(messages_double).to have_received(:create).with(expected_params)
        expect(result).to eq({ success: true, message_id: 'SM123456789' })
      end

      it 'includes custom status callback when channel supports it' do
        allow(twilio_sms).to receive(:respond_to?).and_return(true)
        allow(twilio_sms).to receive(:twilio_delivery_status_index_url).and_return('https://example.com/webhook')

        expected_params = {
          to: test_params[:phone_number],
          content_sid: test_params[:content_sid],
          content_variables: test_params[:content_variables].to_json,
          status_callback: 'https://example.com/webhook',
          from: '+0987654321'
        }

        service.send_csat_template_message(**test_params)

        expect(messages_double).to have_received(:create).with(expected_params)
      end
    end

    context 'when Twilio API returns an error' do
      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'handles Twilio::REST::TwilioError' do
        allow(messages_double).to receive(:create).and_raise(Twilio::REST::TwilioError, 'Invalid phone number')

        result = service.send_csat_template_message(**test_params)

        expect(result).to eq({ success: false, error: 'Invalid phone number' })
        expect(Rails.logger).to have_received(:error).with('Failed to send Twilio template message: Invalid phone number')
      end

      it 'handles Twilio API errors' do
        allow(messages_double).to receive(:create).and_raise(Twilio::REST::TwilioError, 'Content template not found')

        result = service.send_csat_template_message(**test_params)

        expect(result).to eq({ success: false, error: 'Content template not found' })
        expect(Rails.logger).to have_received(:error).with('Failed to send Twilio template message: Content template not found')
      end
    end

    context 'with parameter handling' do
      before do
        allow(messages_double).to receive(:create).and_return(mock_twilio_message)
      end

      it 'handles empty content_variables hash' do
        expected_params = {
          to: test_params[:phone_number],
          content_sid: test_params[:content_sid],
          status_callback: 'http://localhost:3000/twilio/delivery_status',
          from: '+0987654321'
        }

        service.send_csat_template_message(
          phone_number: test_params[:phone_number],
          content_sid: test_params[:content_sid],
          content_variables: {}
        )

        expect(messages_double).to have_received(:create).with(expected_params)
      end

      it 'converts content_variables to JSON when present' do
        variables = { '1' => 'test-uuid', '2' => 'another-value' }
        expected_params = {
          to: test_params[:phone_number],
          content_sid: test_params[:content_sid],
          content_variables: variables.to_json,
          status_callback: 'http://localhost:3000/twilio/delivery_status',
          from: '+0987654321'
        }

        service.send_csat_template_message(
          phone_number: test_params[:phone_number],
          content_sid: test_params[:content_sid],
          content_variables: variables
        )

        expect(messages_double).to have_received(:create).with(expected_params)
      end
    end
  end
end
