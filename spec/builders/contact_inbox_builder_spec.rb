require 'rails_helper'

describe ContactInboxBuilder do
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
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty or invalid: contact phone number')
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
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty or invalid: contact phone number')
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
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty or invalid: contact phone number')
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
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty or invalid: contact phone number')
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
        end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty or invalid: contact email')
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

    describe 'baileys whatsapp inbox phone normalization' do
      let(:baileys_channel) do
        create(:channel_whatsapp, account: account, provider: 'baileys',
                                  sync_templates: false, validate_provider_config: false)
      end
      let(:baileys_inbox) { baileys_channel.inbox }
      let(:contact) { create(:contact, phone_number: '+5511912345678', account: account) }
      let(:canonical_phone) { '+551112345678' }
      let(:canonical_jid) { "#{canonical_phone.delete('+')}@s.whatsapp.net" }

      it 'updates the contact phone when on_whatsapp returns a different canonical jid' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .with(contact.phone_number, deadline: :request)
          .and_return({ 'jid' => canonical_jid, 'exists' => true })

        contact_inbox = described_class.new(
          contact: contact,
          inbox: baileys_inbox,
          validate_whatsapp_phone: true
        ).perform

        expect(contact.reload.phone_number).to eq(canonical_phone)
        expect(contact_inbox.source_id).to eq(canonical_phone.delete('+'))
      end

      it 'rewrites the caller-provided source_id derived from the pre-normalization phone' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => canonical_jid, 'exists' => true })

        contact_inbox = described_class.new(
          contact: contact,
          inbox: baileys_inbox,
          source_id: '5511912345678',
          validate_whatsapp_phone: true
        ).perform

        expect(contact_inbox.source_id).to eq(canonical_phone.delete('+'))
      end

      it 'merges into an existing contact when the canonical phone is already taken' do
        existing_contact = create(:contact, name: 'Existing Maria', phone_number: canonical_phone, account: account)
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => canonical_jid, 'exists' => true })

        contact_inbox = described_class.new(
          contact: contact,
          inbox: baileys_inbox,
          validate_whatsapp_phone: true
        ).perform

        expect(contact_inbox.contact_id).to eq(existing_contact.id)
        expect(existing_contact.reload.phone_number).to eq(canonical_phone)
        expect { contact.reload }.to(raise_error { |error| expect(error.class.name).to eq('ActiveRecord::RecordNotFound') })
      end

      it 'does nothing when on_whatsapp returns the same canonical phone' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => "#{contact.phone_number.delete('+')}@s.whatsapp.net", 'exists' => true })

        expect do
          described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform
        end.not_to(change { contact.reload.phone_number })
      end

      it 'does nothing when on_whatsapp reports exists=false' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => canonical_jid, 'exists' => false })

        expect do
          described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform
        end.not_to(change { contact.reload.phone_number })
      end

      # The builder answers a web request, and rack-timeout cuts that request from outside: the
      # lookup has to give up first, so the conversation is still created.
      it 'asks within the deadline of a web request' do
        deadlines = []
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do |_channel, _phone, **options| # rubocop:disable RSpec/AnyInstance
          deadlines << options[:deadline]
          { 'jid' => canonical_jid, 'exists' => true }
        end

        described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform

        expect(deadlines).to eq([:request])
      end

      it 'creates the contact inbox with the typed phone when the lookup times out' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_raise(Net::ReadTimeout)

        contact_inbox = described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform

        expect(contact_inbox.source_id).to eq(contact.phone_number.delete('+'))
        expect(contact_inbox.whatsapp_missing_checked_at).to be_nil
      end

      it 'swallows provider errors and proceeds with the original phone' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_raise(StandardError, 'baileys boom')

        contact_inbox = nil
        expect do
          contact_inbox = described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform
        end.not_to(change { contact.reload.phone_number })

        expect(contact_inbox.source_id).to eq(contact.phone_number.delete('+'))
      end

      it 'flags the contact inbox when WhatsApp says the number has no account' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => canonical_jid, 'exists' => false })

        freeze_time do
          contact_inbox = described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform

          expect(contact_inbox.reload.whatsapp_missing_checked_at).to eq(Time.current)
        end
      end

      it 'does not flag a number that was corrected while WhatsApp answered' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
          Contact.find(contact.id).update!(phone_number: '+5511900000000')
          { 'jid' => canonical_jid, 'exists' => false }
        end

        contact_inbox = described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform

        expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
      end

      it 'does not restore a flag a reply cleared while WhatsApp answered' do
        flagged = create(:contact_inbox, contact: contact, inbox: baileys_inbox, source_id: '5511912345678',
                                         whatsapp_missing_checked_at: 2.days.ago)
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
          ContactInbox.find(flagged.id).clear_whatsapp_missing!
          { 'jid' => canonical_jid, 'exists' => false }
        end

        described_class.new(contact: contact, inbox: baileys_inbox, source_id: '5511912345678', validate_whatsapp_phone: true).perform

        expect(flagged.reload.whatsapp_missing_checked_at).to be_nil
      end

      # Nothing was flagged, so the reply had no flag to clear: the threads are what show it.
      it 'does not flag a number the contact wrote from while WhatsApp answered' do
        unflagged = create(:contact_inbox, contact: contact, inbox: baileys_inbox, source_id: '5511912345678')
        conversation = create(:conversation, account: account, inbox: baileys_inbox, contact: contact, contact_inbox: unflagged)
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
          create(:message, conversation: conversation, inbox: baileys_inbox, account: account, message_type: :incoming)
          { 'jid' => canonical_jid, 'exists' => false }
        end

        described_class.new(contact: contact, inbox: baileys_inbox, source_id: '5511912345678', validate_whatsapp_phone: true).perform

        expect(unflagged.reload.whatsapp_missing_checked_at).to be_nil
      end

      # A later conversation asks again, so a number that registered since stops warning.
      it 'clears an earlier flag when WhatsApp now knows the number' do
        flagged = create(:contact_inbox, contact: contact, inbox: baileys_inbox, source_id: '5511912345678',
                                         whatsapp_missing_checked_at: 2.days.ago)
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => '5511912345678@s.whatsapp.net', 'exists' => true })

        contact_inbox = described_class.new(contact: contact, inbox: baileys_inbox, source_id: '5511912345678',
                                            validate_whatsapp_phone: true).perform

        expect(contact_inbox.id).to eq(flagged.id)
        expect(flagged.reload.whatsapp_missing_checked_at).to be_nil
      end

      # The "yes" was about the old phone; the "no" a newer lookup left is about the current one.
      it 'does not clear a newer flag for a phone corrected while WhatsApp answered' do
        flagged = create(:contact_inbox, contact: contact, inbox: baileys_inbox, source_id: '5511912345678')
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
          Contact.find(contact.id).update!(phone_number: '+5511900000000')
          ContactInbox.find(flagged.id).update!(whatsapp_missing_checked_at: 1.minute.ago)
          { 'jid' => '5511912345678@s.whatsapp.net', 'exists' => true }
        end

        described_class.new(contact: contact, inbox: baileys_inbox, source_id: '5511912345678', validate_whatsapp_phone: true).perform

        expect(flagged.reload.whatsapp_missing_checked_at).to be_present
      end

      # The merged-into contact's own thread was flagged for the canonical phone, which the
      # answer has just found.
      it 'clears the flag of the contact a merge hands the answer to' do
        existing_contact = create(:contact, phone_number: canonical_phone, account: account)
        flagged = create(:contact_inbox, contact: existing_contact, inbox: baileys_inbox, source_id: canonical_phone.delete('+'),
                                         whatsapp_missing_checked_at: 2.days.ago)
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => canonical_jid, 'exists' => true })

        contact_inbox = described_class.new(contact: contact, inbox: baileys_inbox, validate_whatsapp_phone: true).perform

        expect(contact_inbox.id).to eq(flagged.id)
        expect(flagged.reload.whatsapp_missing_checked_at).to be_nil
      end

      it 'clears the other threads of the contact in the inbox when WhatsApp knows the number' do
        other = create(:contact_inbox, contact: contact, inbox: baileys_inbox, source_id: '551191234567842',
                                       whatsapp_missing_checked_at: 2.days.ago)
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => '5511912345678@s.whatsapp.net', 'exists' => true })

        described_class.new(contact: contact, inbox: baileys_inbox, source_id: '5511912345678', validate_whatsapp_phone: true).perform

        expect(other.reload.whatsapp_missing_checked_at).to be_nil
      end

      # An error is "unknown", not "no": the flag keeps what the last real answer said.
      it 'leaves an earlier flag alone when the lookup fails' do
        checked_at = 2.days.ago.change(usec: 0)
        flagged = create(:contact_inbox, contact: contact, inbox: baileys_inbox, source_id: '5511912345678',
                                         whatsapp_missing_checked_at: checked_at)
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_raise(StandardError, 'baileys boom')

        described_class.new(contact: contact, inbox: baileys_inbox, source_id: '5511912345678', validate_whatsapp_phone: true).perform

        expect(flagged.reload.whatsapp_missing_checked_at).to eq(checked_at)
      end

      it 'does not call on_whatsapp when validate_whatsapp_phone is not requested' do
        expect_any_instance_of(Channel::Whatsapp).not_to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance

        described_class.new(contact: contact, inbox: baileys_inbox).perform
      end

      it 'does not call on_whatsapp for whatsapp inboxes on non-baileys providers' do
        non_baileys_inbox = create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false).inbox
        expect_any_instance_of(Channel::Whatsapp).not_to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance

        described_class.new(contact: contact, inbox: non_baileys_inbox, validate_whatsapp_phone: true).perform
      end
    end

    # A native inbox answers the number check through its paired session. With no session
    # running there is nobody to answer, and the request used to wait out its whole budget
    # and end in a 500 with no contact inbox.
    describe 'native whatsapp inbox that is not connected' do
      let(:native_channel) do
        create(:channel_whatsapp, account: account, provider: 'native',
                                  sync_templates: false, validate_provider_config: false)
      end
      let(:native_inbox) { native_channel.inbox }
      let(:contact) { create(:contact, phone_number: '+5511912345678', account: account) }

      def build
        described_class.new(contact: contact, inbox: native_inbox, validate_whatsapp_phone: true).perform
      end

      [nil, 'close', 'connecting'].each do |state|
        it "keeps the typed number without asking the session when the connection is #{state.inspect}" do
          native_channel.update!(provider_connection: state ? { 'connection' => state } : {})
          expect_any_instance_of(Channel::Whatsapp).not_to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance

          contact_inbox = build

          expect(contact_inbox.source_id).to eq('5511912345678')
          expect(contact.reload.phone_number).to eq('+5511912345678')
        end
      end

      it 'still resolves the canonical number once the session is open' do
        native_channel.update!(provider_connection: { 'connection' => 'open' })
        allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
          .and_return({ 'jid' => '551112345678@s.whatsapp.net', 'exists' => true })

        contact_inbox = build

        expect(contact_inbox.source_id).to eq('551112345678')
        expect(contact.reload.phone_number).to eq('+551112345678')
      end
    end

    context 'when there is a race condition' do
      let(:account) { create(:account) }
      let(:contact) { create(:contact, account: account) }
      let(:contact2) { create(:contact, account: account) }
      let(:channel) { create(:channel_email, account: account) }
      let(:channel_api) { create(:channel_api, account: account) }
      let(:source_id) { 'source_123' }

      it 'handles RecordNotUnique error by updating source_id and retrying' do
        existing_contact_inbox = create(:contact_inbox, contact: contact2, inbox: channel.inbox, source_id: source_id)

        described_class.new(
          contact: contact,
          inbox: channel.inbox,
          source_id: source_id
        ).perform

        expect(ContactInbox.last.source_id).to eq(source_id)
        expect(ContactInbox.last.contact_id).to eq(contact.id)
        expect(ContactInbox.last.inbox_id).to eq(channel.inbox.id)
        expect(existing_contact_inbox.reload.source_id).to include(source_id)
        expect(existing_contact_inbox.reload.source_id).not_to eq(source_id)
      end

      it 'does not update source_id for channels other than email or phone number' do
        create(:contact_inbox, contact: contact2, inbox: channel_api.inbox, source_id: source_id)

        expect do
          described_class.new(
            contact: contact,
            inbox: channel_api.inbox,
            source_id: source_id
          ).perform
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
