require 'rails_helper'

RSpec.describe ContactInbox::SourceIdService do
  let(:contact) { create(:contact, email: 'test@example.com', phone_number: '+1234567890') }

  describe '#generate' do
    context 'when channel is TwilioSms' do
      let(:channel_type) { 'Channel::TwilioSms' }

      context 'with SMS medium' do
        subject { described_class.new(contact: contact, channel_type: channel_type, medium: 'sms') }

        it 'returns phone number as source id' do
          expect(subject.generate).to eq(contact.phone_number)
        end
      end

      context 'with WhatsApp medium' do
        subject { described_class.new(contact: contact, channel_type: channel_type, medium: 'whatsapp') }

        it 'returns whatsapp prefixed phone number as source id' do
          expect(subject.generate).to eq("whatsapp:#{contact.phone_number}")
        end
      end

      context 'with invalid medium' do
        subject { described_class.new(contact: contact, channel_type: channel_type, medium: 'invalid') }

        it 'raises ArgumentError' do
          expect { subject.generate }.to raise_error(ArgumentError, 'Unsupported Twilio medium: invalid')
        end
      end

      context 'without medium' do
        subject { described_class.new(contact: contact, channel_type: channel_type) }

        it 'raises ArgumentError' do
          expect { subject.generate }.to raise_error(ArgumentError, 'medium required for Twilio channel')
        end
      end
    end

    context 'when channel is Whatsapp' do
      subject { described_class.new(contact: contact, channel_type: 'Channel::Whatsapp') }

      it 'returns phone number without + as source id' do
        expect(subject.generate).to eq(contact.phone_number.delete('+'))
      end

      context 'when contact has no phone number' do
        let(:contact) { create(:contact, phone_number: nil) }

        it 'raises ArgumentError' do
          expect { subject.generate }.to raise_error(ArgumentError, 'contact phone number required')
        end
      end
    end

    context 'when channel is Email' do
      subject { described_class.new(contact: contact, channel_type: 'Channel::Email') }

      it 'returns email as source id' do
        expect(subject.generate).to eq(contact.email)
      end

      context 'when contact has no email' do
        let(:contact) { create(:contact, email: nil) }

        it 'raises ArgumentError' do
          expect { subject.generate }.to raise_error(ArgumentError, 'contact email required')
        end
      end
    end

    context 'when channel is SMS' do
      subject { described_class.new(contact: contact, channel_type: 'Channel::Sms') }

      it 'returns phone number as source id' do
        expect(subject.generate).to eq(contact.phone_number)
      end

      context 'when contact has no phone number' do
        let(:contact) { create(:contact, phone_number: nil) }

        it 'raises ArgumentError' do
          expect { subject.generate }.to raise_error(ArgumentError, 'contact phone number required')
        end
      end
    end

    context 'when channel is Api' do
      subject { described_class.new(contact: contact, channel_type: 'Channel::Api') }

      it 'returns a UUID as source id' do
        allow(SecureRandom).to receive(:uuid).and_return('uuid-123')
        expect(subject.generate).to eq('uuid-123')
      end
    end

    context 'when channel is WebWidget' do
      subject { described_class.new(contact: contact, channel_type: 'Channel::WebWidget') }

      it 'returns a UUID as source id' do
        allow(SecureRandom).to receive(:uuid).and_return('uuid-123')
        expect(subject.generate).to eq('uuid-123')
      end
    end

    context 'when channel is unsupported' do
      subject { described_class.new(contact: contact, channel_type: 'Channel::Unknown') }

      it 'raises ArgumentError' do
        expect { subject.generate }.to raise_error(ArgumentError, 'Unsupported operation for this channel: Channel::Unknown')
      end
    end
  end
end
