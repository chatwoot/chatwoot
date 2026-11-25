require 'rails_helper'

RSpec.describe Whatsapp::Session::Outbound::MessageSender do
  subject(:send_message) { described_class.new(message).perform }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }
  let(:contact) { create(:contact, account: channel.account, phone_number: '+5541999990000', identifier: '182736451928374@lid') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '182736451928374') }
  let(:conversation) { create(:conversation, contact: contact, contact_inbox: contact_inbox, inbox: inbox, account: channel.account) }
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     message_type: :outgoing, content: 'olá!')
  end

  before { allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend) }

  it 'sends the text under an id reserved before the request' do
    expect(send_message).to be_present

    command = backend.last_command
    expect(command.to.id).to eq('182736451928374')
    expect(command.content.body).to eq('olá!')
    expect(command.message_id).to eq(message.reload.pending_source_id)
  end

  # A provider that assigns its own message id ignores the reserved one and hands the
  # correlation token back on the echo. EchoMatcher looks the send up by whatever is in
  # `pending_source_id`, so sending anything else as the token means the echo of our own
  # message lands as a second outgoing message written by nobody.
  it 'sends the reservation as the correlation token an echo can be found by' do
    send_message

    command = backend.last_command
    expect(command.client_ref).to eq(message.reload.pending_source_id)
    expect(
      Whatsapp::Session::Inbound::EchoMatcher.new(inbox: inbox, message_id: 'PROVIDER-ASSIGNED', client_ref: command.client_ref).perform
    ).to eq(message)
  end

  it 'reuses the reservation when the job runs twice' do
    send_message
    reserved = message.pending_source_id

    described_class.new(message).perform

    expect(reserved).to be_present
    expect(backend.commands_of('message.send').map(&:message_id).uniq).to eq([reserved])
  end

  # Both layers used to enqueue it: this one from the id it just wrote, and
  # SendOnWhatsappService from the same id returned to it. The second revoke hits a
  # provider that no longer knows the message, and fails five times retrying.
  it 'leaves the revoke of a message deleted mid-send to a single owner' do
    # Deleted after the send started: one deleted beforehand never reaches the provider
    # at all, and the revoke only matters once an id exists to revoke.
    allow(backend).to receive(:send_message).and_wrap_original do |original, command|
      message.update_under_lock!(deleted: true)
      original.call(command)
    end

    expect { Whatsapp::SendOnWhatsappService.new(message: message).perform }
      .to have_enqueued_job(Messages::DeleteOnChannelJob).once
  end

  # Three writers can fill `source_id` on one send. Here the echo wins the race, so it is
  # the one that owns the revoke, and neither the send response nor the outer service may
  # ask the provider to revoke the same message again.
  it 'does not revoke twice when the echo arrives before the send response' do
    allow(backend).to receive(:send_message).and_wrap_original do |original, command|
      message.update_under_lock!(deleted: true)
      Whatsapp::Session::Inbound::EchoMatcher.new(
        inbox: inbox, message_id: 'ECHOED-FIRST', client_ref: message.reload.pending_source_id
      ).perform
      original.call(command)
    end

    expect { Whatsapp::SendOnWhatsappService.new(message: message).perform }
      .to have_enqueued_job(Messages::DeleteOnChannelJob).once
  end

  # A reaction that arrived from the connected phone is stored knowing its target only by
  # the target's WhatsApp id. `Message#ensure_in_reply_to` fills the row id in from it on
  # save, which is what this send relies on: the coverage is here so that a change to that
  # callback shows up as a WhatsApp reaction that stops being sent.
  it 'reacts to a target a phone-originated reaction knows only by its WhatsApp id' do
    target = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                              message_type: :incoming, sender: contact, source_id: '3EB0TARGET')
    message.update!(
      content: '🎉',
      content_attributes: { 'is_reaction' => true, 'in_reply_to_external_id' => target.source_id }
    )

    send_message

    command = backend.last_command
    expect(command.target_id).to eq('3EB0TARGET')
    expect(command.emoji).to eq('🎉')
    expect(message.reload.is_unsupported).to be_falsey
  end

  it 'quotes the message the agent replied to' do
    quoted = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                              message_type: :incoming, sender: contact, source_id: '3EB0QUOTED')
    message.update!(content_attributes: message.content_attributes.merge('in_reply_to_external_id' => quoted.source_id))

    send_message

    expect(backend.last_command.quoted.id).to eq('3EB0QUOTED')
    expect(backend.last_command.quoted.from_me).to be(false)
  end

  it 'flags a message with nothing to send instead of pretending it went out' do
    message.update!(content: nil)

    expect(send_message).to be_nil
    expect(message.reload.is_unsupported).to be(true)
    expect(backend.commands).to be_empty
  end

  context 'with an attachment' do
    let(:message) do
      create(:message, :with_attachment, conversation: conversation, inbox: inbox, account: channel.account,
                                         message_type: :outgoing, content: 'segue a foto')
    end

    it 'sends media the provider fetches by URL, with the text as caption' do
      send_message

      content = backend.last_command.content
      expect(content.kind).to eq('image')
      expect(content.caption).to eq('segue a foto')
      expect(content.ref.url).to be_present
    end
  end

  context 'with a reaction' do
    let(:target) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, sender: contact, source_id: '3EB0TARGET')
    end
    let(:message) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :outgoing, content: '👍',
                       content_attributes: { is_reaction: true, in_reply_to: target.id })
    end

    it 'reacts to the target instead of sending a message' do
      send_message

      command = backend.last_command
      expect(backend.commands_of('message.react').size).to eq(1)
      expect(command.target_id).to eq('3EB0TARGET')
      expect(command.emoji).to eq('👍')
    end
  end

  # The provider refusing for a reason that will not change: the bubble used to stay on
  # "sent" while Sidekiq retried a send that could never work.
  it 'fails the message when the provider refuses for good' do
    allow(backend).to receive(:send_message).and_raise(
      Whatsapp::Session::Errors::RecipientNotOnWhatsapp, 'number is not on whatsapp'
    )

    expect { send_message }.not_to raise_error

    expect(message.reload.status).to eq('failed')
    expect(message.external_error).to eq('number is not on whatsapp')
  end

  # A phone that was logged out stays logged out until somebody scans the QR again, so a
  # retry cannot answer differently: the bubble used to sit on the clock for the four
  # attempts before it said so (#855).
  it 'fails the message at once when the session lost its pairing' do
    allow(backend).to receive(:send_message).and_raise(Whatsapp::Session::Errors::NotPaired, 'not paired')

    expect { send_message }.not_to raise_error

    expect(backend).to have_received(:send_message).once
    expect(message.reload.status).to eq('failed')
    expect(message.external_error).to eq('not paired')
  end

  # A socket that is reconnecting, or a session that is being brought back, can work a
  # few seconds later, so those still take the job down for a retry.
  [Whatsapp::Session::Errors::NotConnected, Whatsapp::Session::Errors::SessionNotFound].each do |error|
    it "lets #{error.name.demodulize} take the job down for a retry" do
      allow(backend).to receive(:send_message).and_raise(error)

      expect { send_message }.to raise_error(error)
      expect(message.reload.status).not_to eq('failed')
    end
  end

  # The other half: a provider that is down answers differently once it is back, so the
  # job has to fail and be retried rather than bury a message the agent could still send.
  it 'lets a provider that may answer differently take the job down with it' do
    allow(backend).to receive(:send_message).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)

    expect { send_message }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
    expect(message.reload.status).not_to eq('failed')
  end

  # `identifier` is account-wide and another channel may own it: an API inbox writes the
  # customer's id there, often an e-mail. Reading that as an address made the contact
  # unreachable on WhatsApp, number and all.
  it 'addresses a contact by its number when the identifier belongs to another channel' do
    contact.update!(identifier: 'cliente@example.com')

    send_message

    expect(backend.last_command.to.to_jid).to eq('5541999990000@s.whatsapp.net')
  end

  context 'when the group only accepts messages from admins' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'native', phone_number: '+5541988887777',
                                validate_provider_config: false, sync_templates: false)
    end
    let(:contact) do
      create(:contact, account: channel.account, identifier: '120363041234567890@g.us',
                       group_type: :group, additional_attributes: { 'announce' => true })
    end

    # Failed, and not raised: the refusal is the same on every retry, and a job dying over
    # it only leaves the bubble reading "sent" until Sidekiq gives up.
    it 'fails the message with a reason the agent can read' do
      expect { send_message }.not_to raise_error

      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to include('administrators')
      expect(backend.commands).to be_empty
    end

    it 'sends when this inbox is an admin recorded without the ninth digit' do
      admin = create(:contact, account: channel.account, phone_number: '+554188887777')
      create(:group_member, group_contact: contact, contact: admin, role: :admin)

      expect { send_message }.not_to raise_error
      expect(backend.commands_of('message.send')).to be_present
    end

    # A roster can name the session's own participant by LID alone, and then the admin
    # contact has no phone at all: comparing numbers answers no to "is this us?" and the
    # inbox refuses to post in a group it administers.
    it 'sends when this inbox is an admin the roster only knows by LID' do
      channel.update_provider_connection!({ 'connection' => 'open', 'lid' => '112233445566778' })
      admin = create(:contact, account: channel.account, identifier: '112233445566778@lid', phone_number: nil)
      create(:group_member, group_contact: contact, contact: admin, role: :admin)

      expect { send_message }.not_to raise_error
      expect(backend.commands_of('message.send')).to be_present
    end

    # The suffix comparison this replaced called these the same line, so the send went
    # out and WhatsApp dropped it in silence while Chatwoot reported it as sent.
    it 'does not mistake a foreign admin sharing the last eight digits for this inbox' do
      admin = create(:contact, account: channel.account, phone_number: '+15588887777')
      create(:group_member, group_contact: contact, contact: admin, role: :admin)

      send_message

      expect(message.reload.status).to eq('failed')
      expect(backend.commands).to be_empty
    end
  end
end
