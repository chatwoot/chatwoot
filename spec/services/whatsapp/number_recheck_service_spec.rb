require 'rails_helper'

describe Whatsapp::NumberRecheckService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                              provider_connection: { 'connection' => 'open' })
  end
  let(:contact) { create(:contact, account: account, phone_number: '+5585988246590') }
  let(:checked_at) { 2.days.ago.change(usec: 0) }
  let(:contact_inbox) do
    create(:contact_inbox, contact: contact, inbox: channel.inbox, source_id: '5585988246590', whatsapp_missing_checked_at: checked_at)
  end
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox, contact: contact, contact_inbox: contact_inbox) }

  def answer(response)
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp).and_return(response) # rubocop:disable RSpec/AnyInstance
  end

  def perform = described_class.new(conversation: conversation).perform

  it 'clears the flag when the number has registered since' do
    answer({ 'jid' => '5585988246590@s.whatsapp.net', 'exists' => true })

    perform

    expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
  end

  # The address this thread sends to has to follow the number WhatsApp knows, the same way a
  # new conversation's does, or clearing the warning would point the agent at a dead address.
  it 'moves the contact and the thread to the canonical number WhatsApp answers with' do
    answer({ 'jid' => '558588246590@s.whatsapp.net', 'exists' => true })

    perform

    expect(contact.reload.phone_number).to eq('+558588246590')
    expect(contact_inbox.reload.source_id).to eq('558588246590')
  end

  it 'keeps the address when another contact inbox of the inbox already holds the canonical one' do
    create(:contact_inbox, inbox: channel.inbox, source_id: '558588246590')
    answer({ 'jid' => '558588246590@s.whatsapp.net', 'exists' => true })

    perform

    expect(contact_inbox.reload.source_id).to eq('5585988246590')
    expect(contact_inbox.whatsapp_missing_checked_at).to be_nil
  end

  # The canonical phone belonged to another contact, whose own thread here warned about it.
  it 'clears the thread of the contact a merge hands the answer to' do
    existing = create(:contact, account: account, phone_number: '+558588246590')
    theirs = create(:contact_inbox, contact: existing, inbox: channel.inbox, source_id: '558588246590', whatsapp_missing_checked_at: checked_at)
    answer({ 'jid' => '558588246590@s.whatsapp.net', 'exists' => true })

    perform

    expect(contact_inbox.reload.contact_id).to eq(existing.id)
    expect(theirs.reload.whatsapp_missing_checked_at).to be_nil
  end

  # A job, outside rack-timeout: it waits as long as the provider may take.
  it 'asks with the provider\'s full deadline' do
    deadlines = []
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do |_channel, _phone, **options| # rubocop:disable RSpec/AnyInstance
      deadlines << options.fetch(:deadline, :provider)
      { 'jid' => '5585988246590@s.whatsapp.net', 'exists' => true }
    end

    perform

    expect(deadlines).to eq([:provider])
  end

  it 'moves the check date forward when the number still has no WhatsApp' do
    answer({ 'jid' => '5585988246590@s.whatsapp.net', 'exists' => false })

    freeze_time do
      perform

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to eq(Time.current)
    end
  end

  it 'keeps the flag and its date when the lookup fails' do
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp).and_raise(StandardError, 'boom') # rubocop:disable RSpec/AnyInstance

    perform

    expect(contact_inbox.reload.whatsapp_missing_checked_at).to eq(checked_at)
  end

  it 'does not ask inside the recheck window' do
    contact_inbox.update!(whatsapp_missing_checked_at: 10.minutes.ago)
    expect_any_instance_of(Channel::Whatsapp).not_to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance

    perform
  end

  # Two agents opening the same stale conversation enqueue two jobs; one lookup is enough.
  it 'leaves the lookup to the worker that already holds the claim' do
    Redis::LockManager.new.lock("whatsapp_number_recheck:#{contact_inbox.id}", 60)
    expect_any_instance_of(Channel::Whatsapp).not_to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance

    perform

    expect(contact_inbox.reload.whatsapp_missing_checked_at).to eq(checked_at)
  end

  it 'does not ask again when the worker before it already answered' do
    asked = 0
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
      asked += 1
      { 'jid' => '5585988246590@s.whatsapp.net', 'exists' => true }
    end
    service = described_class.new(conversation: conversation)
    service.send(:contact_inbox) # memoized with the stale date, as a queued job would hold it
    ContactInbox.find(contact_inbox.id).update!(whatsapp_missing_checked_at: 1.minute.ago) # the other worker

    service.perform

    expect(asked).to eq(0)
    expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
  end

  # The claim keeps other rechecks out, not the writers that outrank a stale answer.
  it 'does not apply the answer when the phone was corrected during the lookup' do
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
      Contact.find(contact.id).update!(phone_number: '+5585911112222')
      { 'jid' => '5585988246590@s.whatsapp.net', 'exists' => false }
    end

    perform

    expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
  end

  # A "yes" about the old phone must not move the contact back off the corrected one.
  it 'does not align the contact to an answer about a phone corrected during the lookup' do
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
      Contact.find(contact.id).update!(phone_number: '+5585911112222')
      { 'jid' => '558588246590@s.whatsapp.net', 'exists' => true }
    end

    perform

    expect(contact.reload.phone_number).to eq('+5585911112222')
  end

  # Another lookup answered while this one waited; the newer answer stands.
  it 'does not clear a flag a newer lookup wrote during this one' do
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
      ContactInbox.find(contact_inbox.id).update!(whatsapp_missing_checked_at: 1.minute.ago)
      { 'jid' => '5585988246590@s.whatsapp.net', 'exists' => true }
    end

    perform

    expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
  end

  it 'does not restore the flag a message from the contact cleared during the lookup' do
    allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) do # rubocop:disable RSpec/AnyInstance
      create(:message, conversation: conversation, inbox: channel.inbox, account: account, message_type: :incoming)
      { 'jid' => '5585988246590@s.whatsapp.net', 'exists' => false }
    end

    perform

    expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
  end

  # The payload is what moves the banner, so the last one has to carry the cleared flag, also
  # when the answer moved the contact to the canonical phone.
  it 'tells the dashboard the flag is gone when the answer aligns the phone' do
    answer({ 'jid' => '558588246590@s.whatsapp.net', 'exists' => true })
    conversation
    payloads = []
    allow(Rails.configuration.dispatcher).to receive(:dispatch) do |event, _time, data|
      payloads << data[:conversation].push_event_data if event == Events::Types::CONVERSATION_UPDATED
    end

    perform

    expect(payloads).not_to be_empty
    expect(payloads.last).to include(id: conversation.display_id, whatsapp_missing_checked_at: nil)
  end

  it 'tells the dashboard what changed' do
    answer({ 'jid' => '5585988246590@s.whatsapp.net', 'exists' => true })
    allow(Rails.configuration.dispatcher).to receive(:dispatch)

    perform

    expect(Rails.configuration.dispatcher).to have_received(:dispatch)
      .with(Events::Types::CONVERSATION_UPDATED, anything, hash_including(conversation: conversation))
  end
end
