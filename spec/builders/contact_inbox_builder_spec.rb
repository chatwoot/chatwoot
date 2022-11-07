require 'rails_helper'

describe ::ContactInboxBuilder do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, email: 'xyc@example.com', phone_number: '+23423424123', account: account) }

  describe '#perform' do
    describe 'twilio sms inbox' do
      let!(:twilio_sms) { create(:channel_twilio_sms, account: account) }
      let!(:twilio_inbox) { create(:inbox, channel: twilio_sms, account: account) }

      it 'does not create contact inbox when contact inbox already exists with the source id provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: twilio_inbox, source_id: contact.phone_number)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox,
          source_id: contact.phone_number
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'does not create contact inbox when contact inbox already exists with phone number and source id is not provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: twilio_inbox, source_id: contact.phone_number)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'creates a new contact inbox when different source id is provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: twilio_inbox, source_id: contact.phone_number)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox,
          source_id: '+224213223422'
        ).perform

        expect(contact_inbox.id).not_to eq(existing_contact_inbox.id)
        expect(contact_inbox.source_id).to eq('+224213223422')
      end

      it 'creates a contact inbox with contact phone number when source id not provided and no contact inbox exists' do
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox
        ).perform

        expect(contact_inbox.source_id).to eq(contact.phone_number)
      end

      it 'raises error when contact phone number is not present and no source id is provided' do
        contact.update!(phone_number: nil)

        expect do
          described_class.new(
            contact: contact,
            inbox: twilio_inbox
          ).perform
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty: contact phone number')
      end
    end

    describe 'twilio whatsapp inbox' do
      let!(:twilio_whatsapp) { create(:channel_twilio_sms, medium: :whatsapp, account: account) }
      let!(:twilio_inbox) { create(:inbox, channel: twilio_whatsapp, account: account) }

      it 'does not create contact inbox when contact inbox already exists with the source id provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: twilio_inbox, source_id: "whatsapp:#{contact.phone_number}")
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox,
          source_id: "whatsapp:#{contact.phone_number}"
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'does not create contact inbox when contact inbox already exists with phone number and source id is not provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: twilio_inbox, source_id: "whatsapp:#{contact.phone_number}")
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'creates a new contact inbox when different source id is provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: twilio_inbox, source_id: "whatsapp:#{contact.phone_number}")
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox,
          source_id: 'whatsapp:+555555'
        ).perform

        expect(contact_inbox.id).not_to eq(existing_contact_inbox.id)
        expect(contact_inbox.source_id).to eq('whatsapp:+555555')
      end

      it 'creates a contact inbox with contact phone number when source id not provided and no contact inbox exists' do
        contact_inbox = described_class.new(
          contact: contact,
          inbox: twilio_inbox
        ).perform

        expect(contact_inbox.source_id).to eq("whatsapp:#{contact.phone_number}")
      end

      it 'raises error when contact phone number is not present and no source id is provided' do
        contact.update!(phone_number: nil)

        expect do
          described_class.new(
            contact: contact,
            inbox: twilio_inbox
          ).perform
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty: contact phone number')
      end
    end

    describe 'whatsapp inbox' do
      let(:whatsapp_inbox) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox }

      it 'does not create contact inbox when contact inbox already exists with the source id provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: contact.phone_number&.delete('+'))
        contact_inbox = described_class.new(
          contact: contact,
          inbox: whatsapp_inbox,
          source_id: contact.phone_number&.delete('+')
        ).perform

        expect(contact_inbox.id).to be(existing_contact_inbox.id)
      end

      it 'does not create contact inbox when contact inbox already exists with phone number and source id is not provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: contact.phone_number&.delete('+'))
        contact_inbox = described_class.new(
          contact: contact,
          inbox: whatsapp_inbox
        ).perform

        expect(contact_inbox.id).to be(existing_contact_inbox.id)
      end

      it 'creates a new contact inbox when different source id is provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: contact.phone_number&.delete('+'))
        contact_inbox = described_class.new(
          contact: contact,
          inbox: whatsapp_inbox,
          source_id: '555555'
        ).perform

        expect(contact_inbox.id).not_to be(existing_contact_inbox.id)
        expect(contact_inbox.source_id).not_to be('555555')
      end

      it 'creates a contact inbox with contact phone number when source id not provided and no contact inbox exists' do
        contact_inbox = described_class.new(
          contact: contact,
          inbox: whatsapp_inbox
        ).perform

        expect(contact_inbox.source_id).to eq(contact.phone_number&.delete('+'))
      end

      it 'raises error when contact phone number is not present and no source id is provided' do
        contact.update!(phone_number: nil)

        expect do
          described_class.new(
            contact: contact,
            inbox: whatsapp_inbox
          ).perform
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty: contact phone number')
      end
    end

    describe 'sms inbox' do
      let!(:sms_channel) { create(:channel_sms, account: account) }
      let!(:sms_inbox) { create(:inbox, channel: sms_channel, account: account) }

      it 'does not create contact inbox when contact inbox already exists with the source id provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: sms_inbox, source_id: contact.phone_number)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: sms_inbox,
          source_id: contact.phone_number
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'does not create contact inbox when contact inbox already exists with phone number and source id is not provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: sms_inbox, source_id: contact.phone_number)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: sms_inbox
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'creates a new contact inbox when different source id is provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: sms_inbox, source_id: contact.phone_number)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: sms_inbox,
          source_id: '+224213223422'
        ).perform

        expect(contact_inbox.id).not_to eq(existing_contact_inbox.id)
        expect(contact_inbox.source_id).to eq('+224213223422')
      end

      it 'creates a contact inbox with contact phone number when source id not provided and no contact inbox exists' do
        contact_inbox = described_class.new(
          contact: contact,
          inbox: sms_inbox
        ).perform

        expect(contact_inbox.source_id).to eq(contact.phone_number)
      end

      it 'raises error when contact phone number is not present and no source id is provided' do
        contact.update!(phone_number: nil)

        expect do
          described_class.new(
            contact: contact,
            inbox: sms_inbox
          ).perform
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty: contact phone number')
      end
    end

    describe 'email inbox' do
      let!(:email_channel) { create(:channel_email, account: account) }
      let!(:email_inbox) { create(:inbox, channel: email_channel, account: account) }

      it 'does not create contact inbox when contact inbox already exists with the source id provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: email_inbox, source_id: contact.email)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: email_inbox,
          source_id: contact.email
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'does not create contact inbox when contact inbox already exists with email and source id is not provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: email_inbox, source_id: contact.email)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: email_inbox
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'creates a new contact inbox when different source id is provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: email_inbox, source_id: contact.email)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: email_inbox,
          source_id: 'xyc@xyc.com'
        ).perform

        expect(contact_inbox.id).not_to eq(existing_contact_inbox.id)
        expect(contact_inbox.source_id).to eq('xyc@xyc.com')
      end

      it 'creates a contact inbox with contact email when source id not provided and no contact inbox exists' do
        contact_inbox = described_class.new(
          contact: contact,
          inbox: email_inbox
        ).perform

        expect(contact_inbox.source_id).to eq(contact.email)
      end

      it 'raises error when contact email is not present and no source id is provided' do
        contact.update!(email: nil)

        expect do
          described_class.new(
            contact: contact,
            inbox: email_inbox
          ).perform
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty: contact email')
      end
    end

    describe 'api inbox' do
      let!(:api_channel) { create(:channel_api, account: account) }
      let!(:api_inbox) { create(:inbox, channel: api_channel, account: account) }

      it 'does not create contact inbox when contact inbox already exists with the source id provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: api_inbox, source_id: 'test')
        contact_inbox = described_class.new(
          contact: contact,
          inbox: api_inbox,
          source_id: 'test'
        ).perform

        expect(contact_inbox.id).to eq(existing_contact_inbox.id)
      end

      it 'creates a new contact inbox when different source id is provided' do
        existing_contact_inbox = create(:contact_inbox, contact: contact, inbox: api_inbox, source_id: SecureRandom.uuid)
        contact_inbox = described_class.new(
          contact: contact,
          inbox: api_inbox,
          source_id: 'test'
        ).perform

        expect(contact_inbox.id).not_to eq(existing_contact_inbox.id)
        expect(contact_inbox.source_id).to eq('test')
      end

      it 'creates a contact inbox with SecureRandom.uuid when source id not provided and no contact inbox exists' do
        contact_inbox = described_class.new(
          contact: contact,
          inbox: api_inbox
        ).perform

        expect(contact_inbox.source_id).not_to be_nil
      end
    end
  end
end
