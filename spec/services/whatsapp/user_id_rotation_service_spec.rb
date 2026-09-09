require 'rails_helper'

describe Whatsapp::UserIdRotationService do
  let!(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let!(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: inbox.account) }
  let(:system) do
    {
      type: 'user_changed_user_id',
      previous_user_id: 'IN.PREVIOUSBSUID',
      user_id: 'IN.CURRENTBSUID'
    }.with_indifferent_access
  end
  let(:messages) { [{ id: 'wamid-system', type: 'system', system: system }.with_indifferent_access] }

  describe '#perform' do
    it 'records the current regular and parent identifiers on the contact owning the previous identifiers' do
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.ENT.PREVIOUSBSUID')
      system.merge!(
        previous_parent_user_id: 'IN.ENT.PREVIOUSBSUID',
        parent_user_id: 'IN.ENT.CURRENTBSUID'
      )

      described_class.new(inbox: inbox, messages: messages).perform

      expect(inbox.contact_inboxes.where(contact: contact).pluck(:source_id)).to include('IN.CURRENTBSUID', 'IN.ENT.CURRENTBSUID')
    end

    it 'falls back to a current identifier when the lifecycle event follows the first message' do
      current = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.CURRENTBSUID')

      described_class.new(inbox: inbox, messages: messages).perform

      expect(inbox.contact_inboxes.find_by(source_id: 'IN.CURRENTBSUID').contact).to eq(current.contact)
    end

    it 'updates the phone and stores its alias for user_changed_number' do
      previous = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      previous.contact.update!(phone_number: '+16505550001')
      system.merge!(type: 'user_changed_number', wa_id: '16505550002')

      described_class.new(inbox: inbox, messages: messages).perform

      expect(previous.contact.reload.phone_number).to eq('+16505550002')
      expect(inbox.contact_inboxes.find_by(source_id: '16505550002').contact).to eq(previous.contact)
    end

    it 'updates an auto-generated phone name when the number changes' do
      previous = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      previous.contact.update!(name: '+16505550001', phone_number: '+16505550001')
      system.merge!(type: 'user_changed_number', wa_id: '16505550002')

      described_class.new(inbox: inbox, messages: messages).perform

      expect(previous.contact.reload).to have_attributes(name: '+16505550002', phone_number: '+16505550002')
    end

    it 'keeps a custom contact name when the number changes' do
      previous = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      previous.contact.update!(name: 'Ada Lovelace', phone_number: '+16505550001')
      system.merge!(type: 'user_changed_number', wa_id: '16505550002')

      described_class.new(inbox: inbox, messages: messages).perform

      expect(previous.contact.reload).to have_attributes(name: 'Ada Lovelace', phone_number: '+16505550002')
    end

    it 'keeps the raw WA ID as the phone while reusing a normalized routing alias' do
      previous = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      previous.contact.update!(phone_number: '+541123456788')
      normalized_phone_alias = create(:contact_inbox, inbox: inbox, contact: contact, source_id: '541123456789')
      system.merge!(type: 'user_changed_number', wa_id: '5491123456789')

      described_class.new(inbox: inbox, messages: messages).perform

      expect(previous.contact.reload.phone_number).to eq('+5491123456789')
      expect(normalized_phone_alias.reload.contact).to eq(previous.contact)
      expect(inbox.contact_inboxes.exists?(source_id: '5491123456789')).to be(false)
    end

    it 'clears the stale phone and does not merge when the new phone belongs to another contact' do
      previous = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      previous.contact.update!(phone_number: '+16505550001')
      conflicting_contact = create(:contact, account: inbox.account, phone_number: '+16505550002')
      system.merge!(type: 'user_changed_number', wa_id: '16505550002')

      expect(Rails.logger).to receive(:warn).with(/already belongs to contact #{conflicting_contact.id}/)

      described_class.new(inbox: inbox, messages: messages).perform

      expect(previous.contact.reload.phone_number).to be_nil
      expect(conflicting_contact.reload.phone_number).to eq('+16505550002')
      expect(inbox.contact_inboxes.exists?(contact: previous.contact, source_id: '16505550002')).to be(false)
    end

    it 'does not claim a new phone alias that belongs to another contact' do
      previous = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      previous.contact.update!(phone_number: '+16505550001')
      conflicting_alias = create(:contact_inbox, inbox: inbox, contact: create(:contact, account: inbox.account), source_id: '16505550002')
      system.merge!(type: 'user_changed_number', wa_id: '16505550002')

      expect(Rails.logger).to receive(:warn).with(/16505550002 already belongs to contact #{conflicting_alias.contact_id}/)

      described_class.new(inbox: inbox, messages: messages).perform

      expect(previous.contact.reload.phone_number).to be_nil
      expect(conflicting_alias.reload.contact_id).not_to eq(previous.contact_id)
    end

    it 'leaves conflicting aliases on separate contacts and reports the collision' do
      previous = create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      current = create(:contact_inbox, inbox: inbox, contact: create(:contact, account: inbox.account), source_id: 'IN.CURRENTBSUID')

      expect(Rails.logger).to receive(:warn).with(/IN.CURRENTBSUID already belongs to contact #{current.contact_id}/)

      described_class.new(inbox: inbox, messages: messages).perform

      expect(previous.reload.contact_id).not_to eq(current.reload.contact_id)
    end

    it 'does not parse unsupported system messages' do
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      system[:type] = 'some_other_system_event'

      expect { described_class.new(inbox: inbox, messages: messages).perform }.not_to change(ContactInbox, :count)
    end

    it 'acquires locks for current identifiers not already locked by the job' do
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.ENT.PREVIOUSBSUID')
      system.merge!(
        previous_parent_user_id: 'IN.ENT.PREVIOUSBSUID',
        parent_user_id: 'IN.ENT.CURRENTBSUID'
      )
      lock_manager = instance_double(Redis::LockManager)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
      expect(lock_manager).to receive(:with_lock)
        .with(format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: inbox.id, sender_id: 'IN.CURRENTBSUID'), 30.seconds)
        .and_yield
        .and_return(true)

      described_class.new(inbox: inbox, messages: messages, job_locked_source_id: 'IN.ENT.CURRENTBSUID').perform
    end

    it 'skips the actual outer job lock when it differs from the system-message preference' do
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.ENT.PREVIOUSBSUID')
      system.merge!(
        previous_parent_user_id: 'IN.ENT.PREVIOUSBSUID',
        parent_user_id: 'IN.ENT.CURRENTBSUID'
      )
      lock_manager = instance_double(Redis::LockManager)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
      expect(lock_manager).to receive(:with_lock)
        .with(format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: inbox.id, sender_id: 'IN.ENT.CURRENTBSUID'), 30.seconds)
        .and_yield
        .and_return(true)

      described_class.new(inbox: inbox, messages: messages, job_locked_source_id: 'IN.CURRENTBSUID').perform
    end

    it 'raises for job retry instead of writing without the identifier lock' do
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      system.merge!(
        previous_parent_user_id: 'IN.ENT.PREVIOUSBSUID',
        parent_user_id: 'IN.ENT.CURRENTBSUID'
      )
      lock_manager = instance_double(Redis::LockManager, with_lock: false)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
      stub_const("#{described_class}::LOCK_RETRY_INTERVAL", 0)

      expect do
        described_class.new(inbox: inbox, messages: messages).perform
      end.to raise_error(MutexApplicationJob::LockAcquisitionError)
      expect(inbox.contact_inboxes.exists?(source_id: 'IN.CURRENTBSUID')).to be(false)
    end

    it 'stays idempotent when the same event is delivered twice' do
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'IN.PREVIOUSBSUID')
      service = described_class.new(inbox: inbox, messages: messages)
      service.perform

      expect { service.perform }.not_to change(ContactInbox, :count)
    end

    it 'does nothing when neither previous nor current identifiers are known' do
      expect { described_class.new(inbox: inbox, messages: messages).perform }.not_to change(ContactInbox, :count)
    end
  end
end
