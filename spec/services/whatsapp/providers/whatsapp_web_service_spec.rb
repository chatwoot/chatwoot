require 'rails_helper'

RSpec.describe Whatsapp::Providers::WhatsappWebService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_web', validate_provider_config: false, sync_templates: false) }
  let(:message) { create(:message, inbox: whatsapp_channel.inbox) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  describe '#get_accessible_attachment_url' do
    context 'when attachment has file attached' do
      let(:attachment) do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(
          io: StringIO.new('fake image'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        attachment.save!
        attachment
      end

      it 'returns file_url when available' do
        expect(attachment.file).to be_attached
        url = service.send(:get_accessible_attachment_url, attachment)
        expect(url).to be_present
        expect(url).to include('test.jpg')
      end
    end

    context 'when attachment has no file' do
      let(:attachment) { message.attachments.create!(account_id: message.account_id, file_type: :image) }

      it 'returns nil' do
        url = service.send(:get_accessible_attachment_url, attachment)
        expect(url).to be_nil
      end
    end
  end

  describe '#contact_info retry logic' do
    # Create service without factory to avoid callback issues
    let(:channel_double) { double('Channel::Whatsapp', phone_number: '5521987654321', provider_config: {}) }
    let(:test_service) { described_class.new(whatsapp_channel: channel_double) }

    context 'when gateway has transient connection failures' do
      let(:identifier) { '5511999887766@s.whatsapp.net' }

      before do
        # Mock sleep to make tests fast
        allow(test_service).to receive(:sleep)
        # Mock API path
        allow(test_service).to receive(:api_path).and_return('http://localhost:3001/5521987654321')
        # Mock API headers
        allow(test_service).to receive(:api_headers).and_return({})
      end

      it 'retries on connection refused and succeeds on retry' do
        call_count = 0
        allow(HTTParty).to receive(:get) do
          call_count += 1
          raise Errno::ECONNREFUSED, 'Connection refused' if call_count == 1

          response_double = double('response')
          allow(response_double).to receive(:success?).and_return(true)
          allow(response_double).to receive(:[]).with('results').and_return({ 'pushname' => 'John Doe' })
          response_double
        end

        # Should log retry attempt
        expect(Rails.logger).to receive(:info).with(/Retrying contact_info/)

        result = test_service.contact_info(identifier)

        expect(result).to eq({ name: 'John Doe', type: 'contact' })
        expect(call_count).to eq(2) # Initial attempt + 1 retry
      end

      it 'retries on timeout and succeeds on retry' do
        call_count = 0
        allow(HTTParty).to receive(:get) do
          call_count += 1
          raise Net::OpenTimeout, 'Connection timeout' if call_count == 1

          response_double = double('response')
          allow(response_double).to receive(:success?).and_return(true)
          allow(response_double).to receive(:[]).with('results').and_return({ 'pushname' => 'Jane Doe' })
          response_double
        end

        expect(Rails.logger).to receive(:info).with(/Retrying contact_info/)

        result = test_service.contact_info(identifier)

        expect(result).to eq({ name: 'Jane Doe', type: 'contact' })
        expect(call_count).to eq(2)
      end

      it 'exhausts retries and re-raises error after 3 attempts' do
        call_count = 0
        allow(HTTParty).to receive(:get) do
          call_count += 1
          raise Errno::ECONNREFUSED, 'Connection refused'
        end

        # Allow logging without strict expectations to avoid mock errors
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        expect do
          test_service.contact_info(identifier)
        end.to raise_error(Errno::ECONNREFUSED)

        expect(call_count).to eq(4) # Initial attempt + 3 retries
      end

      it 'uses exponential backoff between retries' do
        allow(HTTParty).to receive(:get).and_raise(Errno::ECONNREFUSED.new('Connection refused'))

        # Mock sleep to verify backoff pattern - override the before block mock
        sleep_durations = []
        allow(test_service).to receive(:sleep) { |duration| sleep_durations << duration }

        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        expect do
          test_service.contact_info(identifier)
        end.to raise_error(Errno::ECONNREFUSED)

        # Should sleep 1s, 2s, 4s (exponential backoff)
        expect(sleep_durations).to eq([1, 2, 4])
      end
    end
  end
end
