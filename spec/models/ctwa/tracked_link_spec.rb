require 'rails_helper'

RSpec.describe Ctwa::TrackedLink do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+15551234567', provider: 'whatsapp_cloud', validate_provider_config: false,
                              sync_templates: false)
  end
  let(:inbox) { channel.inbox }

  describe 'validations' do
    it 'generates a valid code on create' do
      link = described_class.create!(account: account, inbox: inbox, name: 'Flyer Julho')

      expect(link.code).to match(/\A[A-Z2-9]{6}\z/)
    end

    it 'requires a globally unique code' do
      described_class.create!(account: account, inbox: inbox, name: 'Flyer Julho', code: 'ABC234')

      duplicate = described_class.new(account: account, inbox: inbox, name: 'Outro flyer', code: 'ABC234')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to be_present
    end
  end

  describe '#wa_link' do
    it 'builds a WhatsApp link with the inbox phone and escaped text plus code' do
      link = described_class.create!(
        account: account,
        inbox: inbox,
        name: 'QR Loja',
        code: 'ZZZ999',
        prefilled_text: 'Quero atendimento'
      )

      expect(link.wa_link).to eq('https://wa.me/15551234567?text=Quero+atendimento+%23ZZZ999')
    end
  end
end
