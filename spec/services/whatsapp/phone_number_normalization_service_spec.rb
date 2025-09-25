require 'rails_helper'

RSpec.describe Whatsapp::PhoneNumberNormalizationService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:service) { described_class.new(inbox) }

  describe '#normalize_and_find_contact_by_provider' do
    context 'when handling Brazilian numbers' do
      context 'with WhatsApp Cloud provider' do
        it 'normalizes old format and finds existing contact with new format' do
          # Create existing contact with new format (13 digits)
          create(:contact_inbox, inbox: inbox, source_id: '5541988887777')

          # Incoming old format (12 digits)
          result = service.normalize_and_find_contact_by_provider('554188887777', :cloud)

          expect(result).to eq('5541988887777')
        end

        it 'returns original if no existing contact found' do
          result = service.normalize_and_find_contact_by_provider('554188887777', :cloud)

          expect(result).to eq('554188887777')
        end
      end

      context 'with Twilio provider' do
        it 'normalizes old format and finds existing contact with new format' do
          # Create existing contact with new format (Twilio format with 13 digits)
          create(:contact_inbox, inbox: inbox, source_id: 'whatsapp:+5541988887777')

          # Incoming old format (Twilio format with 12 digits)
          result = service.normalize_and_find_contact_by_provider('whatsapp:+554188887777', :twilio)

          expect(result).to eq('whatsapp:+5541988887777')
        end

        it 'returns original if no existing contact found' do
          result = service.normalize_and_find_contact_by_provider('whatsapp:+554188887777', :twilio)

          expect(result).to eq('whatsapp:+554188887777')
        end
      end
    end

    context 'when handling Argentine numbers' do
      context 'with WhatsApp Cloud provider' do
        it 'normalizes number with 9 and finds existing contact without 9' do
          # Create existing contact with normalized format (without 9)
          create(:contact_inbox, inbox: inbox, source_id: '541123456789')

          # Incoming format with 9 after country code
          result = service.normalize_and_find_contact_by_provider('5491123456789', :cloud)

          expect(result).to eq('541123456789')
        end
      end

      context 'with Twilio provider' do
        it 'normalizes number with 9 and finds existing contact without 9' do
          # Create existing contact with normalized format (Twilio format without 9)
          create(:contact_inbox, inbox: inbox, source_id: 'whatsapp:+541123456789')

          # Incoming format with 9 after country code (Twilio format)
          result = service.normalize_and_find_contact_by_provider('whatsapp:+5491123456789', :twilio)

          expect(result).to eq('whatsapp:+541123456789')
        end
      end
    end

    context 'when handling unsupported countries' do
      it 'returns original number for WhatsApp Cloud' do
        result = service.normalize_and_find_contact_by_provider('919876543210', :cloud)

        expect(result).to eq('919876543210')
      end

      it 'returns original number for Twilio' do
        result = service.normalize_and_find_contact_by_provider('whatsapp:+919876543210', :twilio)

        expect(result).to eq('whatsapp:+919876543210')
      end
    end

    context 'when handling invalid provider' do
      it 'raises ArgumentError for unsupported provider' do
        expect do
          service.normalize_and_find_contact_by_provider('919876543210', :unknown)
        end.to raise_error(ArgumentError, 'Unsupported provider: unknown. Use :cloud or :twilio')
      end
    end
  end
end
