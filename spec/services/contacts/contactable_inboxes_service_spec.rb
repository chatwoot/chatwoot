require 'rails_helper'

describe Contacts::ContactableInboxesService do
  before do
    stub_request(:post, /graph.facebook.com/)
  end

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: 'contact@example.com', phone_number: '+2320000') }
  let!(:twilio_sms) { create(:channel_twilio_sms, account: account) }
  let!(:twilio_sms_inbox) { create(:inbox, channel: twilio_sms, account: account) }
  let!(:twilio_whatsapp) { create(:channel_twilio_sms, medium: :whatsapp, account: account) }
  let!(:twilio_whatsapp_inbox) { create(:inbox, channel: twilio_whatsapp, account: account) }
  let!(:email_channel) { create(:channel_email, account: account) }
  let!(:email_inbox) { create(:inbox, channel: email_channel, account: account) }
  let!(:api_channel) { create(:channel_api, account: account) }
  let!(:api_inbox) { create(:inbox, channel: api_channel, account: account) }
  let!(:website_inbox) { create(:inbox, channel: create(:channel_widget, account: account), account: account) }
  let!(:sms_inbox) { create(:inbox, channel: create(:channel_sms, account: account), account: account) }

  describe '#get' do
    it 'returns the contactable inboxes for the contact' do
      contactable_inboxes = described_class.new(contact: contact).get

      expect(contactable_inboxes).to include({ source_id: contact.phone_number, inbox: twilio_sms_inbox })
      expect(contactable_inboxes).to include({ source_id: "whatsapp:#{contact.phone_number}", inbox: twilio_whatsapp_inbox })
      expect(contactable_inboxes).to include({ source_id: contact.email, inbox: email_inbox })
      expect(contactable_inboxes).to include({ source_id: contact.phone_number, inbox: sms_inbox })
    end

    it 'doest not return the non contactable inboxes for the contact' do
      facebook_channel = create(:channel_facebook_page, account: account)
      facebook_inbox = create(:inbox, channel: facebook_channel, account: account)
      twitter_channel = create(:channel_twitter_profile, account: account)
      twitter_inbox = create(:inbox, channel: twitter_channel, account: account)

      contactable_inboxes = described_class.new(contact: contact).get

      expect(contactable_inboxes.pluck(:inbox)).not_to include(website_inbox)
      expect(contactable_inboxes.pluck(:inbox)).not_to include(facebook_inbox)
      expect(contactable_inboxes.pluck(:inbox)).not_to include(twitter_inbox)
    end

    context 'when api inbox is available' do
      it 'returns existing source id if contact inbox exists' do
        contact_inbox = create(:contact_inbox, inbox: api_inbox, contact: contact)

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes).to include({ source_id: contact_inbox.source_id, inbox: api_inbox })
      end
    end

    context 'when a WhatsApp Cloud inbox is available' do
      let!(:whatsapp_inbox) do
        create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false).inbox
      end

      it 'uses the phone number when the contact has one' do
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'MY.2081978709342942')

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes).to include({ source_id: '2320000', inbox: whatsapp_inbox })
      end

      it 'uses the BSUID when the contact has no phone number and one identity in the inbox' do
        contact.update!(phone_number: nil)
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'MY.2081978709342942')

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes).to include({ source_id: 'MY.2081978709342942', inbox: whatsapp_inbox })
      end

      it 'does not choose between several BSUIDs in the inbox' do
        contact.update!(phone_number: nil)
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'MY.ENT.9081726354')
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'MY.2081978709342942')

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes.pluck(:inbox)).not_to include(whatsapp_inbox)
      end

      it 'only offers the inbox where the contact holds the BSUID' do
        contact.update!(phone_number: nil)
        other_inbox = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false,
                                                sync_templates: false).inbox
        create(:contact_inbox, contact: contact, inbox: other_inbox, source_id: 'MY.2081978709342942')

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes.pluck(:inbox)).not_to include(whatsapp_inbox)
        expect(contactable_inboxes).to include({ source_id: 'MY.2081978709342942', inbox: other_inbox })
      end
    end

    context 'when a WhatsApp 360dialog inbox is available' do
      it 'does not offer the inbox to a contact with only a BSUID' do
        contact.update!(phone_number: nil)
        dialog_inbox = create(:channel_whatsapp, account: account, provider: 'default', validate_provider_config: false,
                                                 sync_templates: false).inbox
        create(:contact_inbox, contact: contact, inbox: dialog_inbox, source_id: 'MY.2081978709342942')

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes.pluck(:inbox)).not_to include(dialog_inbox)
      end
    end

    context 'when website inbox is available' do
      it 'returns existing source id if contact inbox exists without any conversations' do
        contact_inbox = create(:contact_inbox, inbox: website_inbox, contact: contact)

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes).to include({ source_id: contact_inbox.source_id, inbox: website_inbox })
      end

      it 'does not return existing source id if contact inbox exists with conversations' do
        contact_inbox = create(:contact_inbox, inbox: website_inbox, contact: contact)
        create(:conversation, contact: contact, inbox: website_inbox, contact_inbox: contact_inbox)

        contactable_inboxes = described_class.new(contact: contact).get
        expect(contactable_inboxes.pluck(:inbox)).not_to include(website_inbox)
      end
    end
  end
end
