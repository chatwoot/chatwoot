require 'rails_helper'

RSpec.describe Whatsapp::Providers::WhatsappWebService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_web', validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  describe '#sanitize_number' do
    context 'with group JIDs' do
      it 'preserves group JIDs without modification' do
        group_jids = [
          '120363025246125486@g.us',
          '1234567890@g.us',
          '555999888777666@g.us'
        ]

        group_jids.each do |jid|
          result = service.send(:sanitize_number, jid)
          expect(result).to eq(jid), "Expected #{jid} to be preserved, got #{result}"
        end
      end

      it 'preserves group JIDs even with + prefix' do
        result = service.send(:sanitize_number, '+120363025246125486@g.us')
        expect(result).to eq('120363025246125486@g.us')
      end
    end

    context 'with individual phone numbers' do
      it 'adds @s.whatsapp.net suffix to plain numbers' do
        numbers = %w[
          5511999887766
          1234567890
          555999888777
        ]

        numbers.each do |number|
          result = service.send(:sanitize_number, number)
          expect(result).to eq("#{number}@s.whatsapp.net")
        end
      end

      it 'preserves numbers that already have @s.whatsapp.net' do
        number_with_suffix = '5511999887766@s.whatsapp.net'
        result = service.send(:sanitize_number, number_with_suffix)
        expect(result).to eq(number_with_suffix)
      end

      it 'removes + prefix from phone numbers' do
        result = service.send(:sanitize_number, '+5511999887766')
        expect(result).to eq('5511999887766@s.whatsapp.net')
      end
    end

    context 'with edge cases' do
      it 'handles empty strings' do
        result = service.send(:sanitize_number, '')
        expect(result).to eq('@s.whatsapp.net')
      end

      it 'handles nil input' do
        result = service.send(:sanitize_number, nil)
        expect(result).to eq('@s.whatsapp.net')
      end

      it 'handles strings with whitespace' do
        result = service.send(:sanitize_number, '  5511999887766  ')
        expect(result).to eq('5511999887766@s.whatsapp.net')
      end

      it 'preserves group JIDs with whitespace' do
        result = service.send(:sanitize_number, '  120363025246125486@g.us  ')
        expect(result).to eq('120363025246125486@g.us')
      end
    end
  end
end
