require 'rails_helper'

describe ConversationBuilder do
  let(:account) { create(:account) }
  let!(:sms_channel) { create(:channel_sms, account: account) }
  let!(:api_channel) { create(:channel_api, account: account) }
  let!(:sms_inbox) { create(:inbox, channel: sms_channel, account: account) }
  let!(:api_inbox) { create(:inbox, channel: api_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_sms_inbox) { create(:contact_inbox, contact: contact, inbox: sms_inbox) }
  let(:contact_api_inbox) { create(:contact_inbox, contact: contact, inbox: api_inbox) }

  describe '#perform' do
    it 'creates sms conversation' do
      conversation = described_class.new(
        contact_inbox: contact_sms_inbox,
        params: {}
      ).perform

      expect(conversation.contact_inbox_id).to eq(contact_sms_inbox.id)
    end

    it 'creates api conversation' do
      conversation = described_class.new(
        contact_inbox: contact_api_inbox,
        params: {}
      ).perform

      expect(conversation.contact_inbox_id).to eq(contact_api_inbox.id)
    end

    context 'when lock_to_single_conversation is true for sms inbox' do
      before do
        sms_inbox.update!(lock_to_single_conversation: true)
      end

      it 'creates sms conversation when existing conversation is not present' do
        conversation = described_class.new(
          contact_inbox: contact_sms_inbox,
          params: {}
        ).perform

        expect(conversation.contact_inbox_id).to eq(contact_sms_inbox.id)
      end

      it 'returns last from existing sms conversations when existing conversation is not present' do
        create(:conversation, contact_inbox: contact_sms_inbox, contact: contact, inbox: sms_inbox)
        existing_conversation = create(:conversation, contact_inbox: contact_sms_inbox, contact: contact, inbox: sms_inbox)
        conversation = described_class.new(
          contact_inbox: contact_sms_inbox,
          params: {}
        ).perform

        expect(conversation.id).to eq(existing_conversation.id)
      end
    end

    context 'when lock_to_single_conversation is true for api inbox' do
      before do
        api_inbox.update!(lock_to_single_conversation: true)
      end

      it 'creates conversation when existing api conversation is not present' do
        conversation = described_class.new(
          contact_inbox: contact_api_inbox,
          params: {}
        ).perform

        expect(conversation.contact_inbox_id).to eq(contact_api_inbox.id)
      end

      it 'returns last from existing api conversations when existing conversation is not present' do
        create(:conversation, contact_inbox: contact_api_inbox, contact: contact, inbox: api_inbox)
        existing_conversation = create(:conversation, contact_inbox: contact_api_inbox, contact: contact, inbox: api_inbox)
        conversation = described_class.new(
          contact_inbox: contact_api_inbox,
          params: {}
        ).perform

        expect(conversation.id).to eq(existing_conversation.id)
      end
    end

    context 'when lock_to_single_conversation is true for whatsapp inbox with multiple contact_inboxes' do
      let!(:whatsapp_channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
      let!(:whatsapp_inbox) { whatsapp_channel.inbox }
      let(:contact_with_phone) { create(:contact, account: account, phone_number: '+5511912345678') }

      before { whatsapp_inbox.update!(lock_to_single_conversation: true) }

      it 'finds conversation from different contact_inbox with same contact' do
        lid_contact_inbox = create(:contact_inbox, contact: contact_with_phone, inbox: whatsapp_inbox, source_id: '12345678')
        existing_conversation = create(:conversation, contact_inbox: lid_contact_inbox, inbox: whatsapp_inbox, contact: contact_with_phone)
        phone_contact_inbox = create(:contact_inbox, contact: contact_with_phone, inbox: whatsapp_inbox, source_id: '5511912345678')

        conversation = described_class.new(contact_inbox: phone_contact_inbox, params: {}).perform

        expect(conversation.id).to eq(existing_conversation.id)
      end
    end

    # An email inbox that continues the contact's open case answers here too, so anything opening a
    # conversation on the customer's behalf (an escalation from another channel, an integration)
    # joins the case the customer is already in instead of starting a second one beside it.
    context 'when the email inbox continues the open case' do
      let!(:email_channel) { create(:channel_email, account: account, continue_open_conversation: true) }
      let(:email_inbox) { email_channel.inbox }
      let(:contact_email_inbox) { create(:contact_inbox, contact: contact, inbox: email_inbox) }

      it 'continues the open conversation instead of creating another' do
        open_conversation = create(:conversation, account: account, inbox: email_inbox, contact: contact, status: :open)

        conversation = described_class.new(contact_inbox: contact_email_inbox, params: {}).perform

        expect(conversation.id).to eq(open_conversation.id)
      end

      it 'creates a conversation when the previous one is resolved' do
        create(:conversation, account: account, inbox: email_inbox, contact: contact, status: :resolved)

        expect do
          described_class.new(contact_inbox: contact_email_inbox, params: {}).perform
        end.to change(Conversation, :count).by(1)
      end

      # The caller believes it created a conversation carrying its attributes. Dropping them, which
      # is what plain reuse does, leaves it reading a link that was never written.
      it 'merges the requested attributes into the conversation it continued' do
        open_conversation = create(
          :conversation, account: account, inbox: email_inbox, contact: contact, status: :resolved,
                         additional_attributes: { 'mail_subject' => 'Original subject', 'source' => 'email' },
                         custom_attributes: { 'origin_thread' => 'first', 'keep_me' => 'yes' }
        )
        open_conversation.update!(status: :open)

        conversation = described_class.new(
          contact_inbox: contact_email_inbox,
          params: ActionController::Parameters.new(
            status: 'open',
            additional_attributes: { mail_subject: 'Newer subject', origin: 'whatsapp' },
            custom_attributes: { origin_thread: 'second' }
          )
        ).perform

        expect(conversation.id).to eq(open_conversation.id)
        expect(conversation.additional_attributes['origin']).to eq('whatsapp')
        expect(conversation.additional_attributes['source']).to eq('email')
        expect(conversation.custom_attributes['origin_thread']).to eq('second')
        expect(conversation.custom_attributes['keep_me']).to eq('yes')
      end

      # mail_subject names the conversation and titles the outgoing reply, so it stays as the
      # thread that opened the case wrote it.
      it 'keeps the original mail_subject' do
        open_conversation = create(
          :conversation, account: account, inbox: email_inbox, contact: contact, status: :open,
                         additional_attributes: { 'mail_subject' => 'Original subject' }
        )

        described_class.new(
          contact_inbox: contact_email_inbox,
          params: ActionController::Parameters.new(additional_attributes: { mail_subject: 'Newer subject' })
        ).perform

        expect(open_conversation.reload.additional_attributes['mail_subject']).to eq('Original subject')
      end

      # Routing a conversation somebody is already working on would take the case away from them.
      it 'does not reassign the conversation it continued' do
        agent = create(:user, account: account)
        team = create(:team, account: account)
        open_conversation = create(
          :conversation, account: account, inbox: email_inbox, contact: contact, status: :open, assignee: agent
        )

        described_class.new(
          contact_inbox: contact_email_inbox,
          params: ActionController::Parameters.new(assignee_id: nil, team_id: team.id)
        ).perform

        open_conversation.reload
        expect(open_conversation.assignee_id).to eq(agent.id)
        expect(open_conversation.team_id).to be_nil
      end

      it 'reopens a conversation the caller asked to open' do
        snoozed = create(:conversation, account: account, inbox: email_inbox, contact: contact, status: :snoozed)

        described_class.new(
          contact_inbox: contact_email_inbox,
          params: ActionController::Parameters.new(status: 'open')
        ).perform

        expect(snoozed.reload).to be_open
      end

      # Continuing writes to the conversation and hands it back with its latest message, so a
      # caller who could not read it through any other endpoint must not reach it through this one.
      context 'when the caller may not act on the open conversation' do
        let(:outsider) { create(:user, account: account, role: :agent) }
        let!(:open_conversation) do
          create(:conversation, account: account, inbox: email_inbox, contact: contact, status: :open)
        end

        before do
          Current.user = outsider
          Current.account = account
          Current.account_user = outsider.account_users.find_by(account: account)
        end

        after { Current.reset }

        it 'creates its own conversation instead of continuing that one' do
          expect do
            described_class.new(contact_inbox: contact_email_inbox, params: {}).perform
          end.to change(Conversation, :count).by(1)
        end

        it 'leaves the conversation it refused untouched' do
          described_class.new(
            contact_inbox: contact_email_inbox,
            params: ActionController::Parameters.new(custom_attributes: { escalation: 'second' })
          ).perform

          expect(open_conversation.reload.custom_attributes).to be_empty
        end
      end

      it 'continues the open conversation for a caller who has access to the inbox' do
        member = create(:user, account: account, role: :agent)
        create(:inbox_member, user: member, inbox: email_inbox)
        open_conversation = create(:conversation, account: account, inbox: email_inbox, contact: contact, status: :open)
        Current.user = member
        Current.account = account
        Current.account_user = member.account_users.find_by(account: account)

        conversation = described_class.new(contact_inbox: contact_email_inbox, params: {}).perform

        expect(conversation.id).to eq(open_conversation.id)
      ensure
        Current.reset
      end
    end

    # The setting belongs to the email channel, and nothing about the other channels moves.
    context 'when the email inbox does not continue the open case' do
      let!(:email_channel) { create(:channel_email, account: account) }
      let(:contact_email_inbox) { create(:contact_inbox, contact: contact, inbox: email_channel.inbox) }

      it 'creates a conversation even with one open' do
        create(:conversation, account: account, inbox: email_channel.inbox, contact: contact, status: :open)

        expect do
          described_class.new(contact_inbox: contact_email_inbox, params: {}).perform
        end.to change(Conversation, :count).by(1)
      end
    end

    it 'does not continue an open conversation on a non-email inbox' do
      create(:conversation, account: account, inbox: sms_inbox, contact: contact, status: :open)

      expect do
        described_class.new(contact_inbox: contact_sms_inbox, params: {}).perform
      end.to change(Conversation, :count).by(1)
    end
  end
end
