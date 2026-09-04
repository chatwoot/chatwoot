require 'rails_helper'

describe Whatsapp::PhoneNumberNormalizationService do
  let(:account) { create(:account) }
  let(:whatsapp_inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }
  let(:twilio_inbox) { create(:channel_twilio_sms, account: account, medium: :whatsapp).inbox }

  describe '#normalize_and_find_contact_by_provider' do
    context 'when the country has no normalizer' do
      it 'returns the incoming number untouched' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '447700900123')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('447700900123', :cloud)).to eq('447700900123')
      end
    end

    context 'when no contact_inbox matches any variant' do
      it 'returns the incoming number so a new contact is created in the incoming format' do
        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('554188887777', :cloud)).to eq('554188887777')
      end
    end

    context 'with Brazil numbers' do
      it 'finds a contact stored with the mobile 9 when the number arrives without it' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '5541988887777')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('554188887777', :cloud)).to eq('5541988887777')
      end

      it 'finds a contact stored without the mobile 9 when the number arrives with it' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '554188887777')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('5541988887777', :cloud)).to eq('554188887777')
      end

      it 'prefers the normalized format when both variants already exist' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '554188887777')
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '5541988887777')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('554188887777', :cloud)).to eq('5541988887777')
      end

      it 'does not strip the ninth digit when what remains is a landline' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '554132345678')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('5541932345678', :cloud)).to eq('5541932345678')
      end

      it 'does not match a contact belonging to another inbox' do
        other_inbox = create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox
        create(:contact_inbox, inbox: other_inbox, source_id: '5541988887777')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('554188887777', :cloud)).to eq('554188887777')
      end
    end

    context 'with Argentina numbers' do
      it 'finds a contact stored without the 9 when the number arrives with it' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '541112345678')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('5491112345678', :cloud)).to eq('541112345678')
      end

      # 549 and 54 are different subscribers, not two spellings of one: the no-9 form is a valid
      # landline in the same area code, so it must never be offered as an alternate.
      it 'does not route a mobile sender into a landline contact inbox' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '5491112345678')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('541112345678', :cloud)).to eq('541112345678')
      end
    end

    context 'with Mexico numbers' do
      it 'finds a contact stored without the mobile 1 when the number arrives with it' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '525512345678')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('5215512345678', :cloud)).to eq('525512345678')
      end

      it 'finds a contact stored with the mobile 1 when the number arrives without it' do
        create(:contact_inbox, inbox: whatsapp_inbox, source_id: '5215512345678')

        expect(described_class.new(whatsapp_inbox).normalize_and_find_contact_by_provider('525512345678', :cloud)).to eq('5215512345678')
      end
    end

    context 'with the twilio provider' do
      it 'matches an alternate variant stored in the whatsapp:+ format' do
        create(:contact_inbox, inbox: twilio_inbox, source_id: 'whatsapp:+554188887777')

        source_id = described_class.new(twilio_inbox).normalize_and_find_contact_by_provider('whatsapp:+5541988887777', :twilio)

        expect(source_id).to eq('whatsapp:+554188887777')
      end

      it 'returns the incoming prefixed number when nothing matches' do
        source_id = described_class.new(twilio_inbox).normalize_and_find_contact_by_provider('whatsapp:+5541988887777', :twilio)

        expect(source_id).to eq('whatsapp:+5541988887777')
      end
    end
  end
end
