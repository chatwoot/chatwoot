require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::CallOffer do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) do
    create(:channel_whatsapp, provider: 'native', phone_number: '+5541988887777',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:caller_party) { model::Party.new(phone: '5511988887777', lid: nil, push_name: 'Ana Souza', verified_name: nil) }
  let(:event) { model::Event.build(offer) }
  let(:call_id) { 'call-1' }
  let(:video) { false }
  let(:offer) do
    model::Events::CallOffer.new(call_id: call_id, from: caller_party, video: video, timestamp: 1_755_440_000_123)
  end

  def activity_lines
    inbox.messages.where(message_type: :activity)
  end

  it 'writes the call into the caller\'s conversation' do
    expect(dispatch).to eq(:handled)

    line = activity_lines.last
    expect(line.content).to eq('Ana Souza called on WhatsApp')
    expect(line.conversation.contact.phone_number).to eq('+5511988887777')
  end

  # Only the notice says what kind of call it is, and an agent reading the thread back
  # later is the one who needs to know which it was.
  context 'when the call is a video one' do
    let(:video) { true }

    it 'says so' do
      dispatch

      expect(activity_lines.last.content).to eq('Ana Souza made a video call on WhatsApp')
    end
  end

  # The call's own instant, so a line written from a redelivery minutes later is dated
  # when the phone rang rather than when the job got to it.
  it 'dates the line when the phone rang' do
    dispatch

    expect(activity_lines.last.created_at).to be_within(1.second).of(Time.zone.at(1_755_440_000.123))
  end

  # The connector publishes one offer per call, but a redelivery crosses instances and
  # the deduplication there is per session. Two lines for one ring is noise in a thread
  # an agent reads to find out what happened.
  it 'writes one line however many times the same call arrives' do
    expect(dispatch).to eq(:handled)
    expect(Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)).to eq(:duplicate)
    expect(activity_lines.count).to eq(1)
  end

  # A capability a provider does not declare is a promise the inbox payload must not
  # make. Uazapi forwards no calls, so an inbox on it would otherwise show a thread that
  # never fills.
  it 'is ignored on a provider that does not do calls' do
    allow(Whatsapp::Session::Registry).to receive(:capabilities_for).and_return(%w[groups])

    expect(dispatch).to eq(:ignored)
    expect(activity_lines).to be_empty
  end

  # The same rule every inbound path applies: a blocked contact stops generating
  # messages and notifications.
  it 'is ignored for a blocked contact' do
    contact = create(:contact, account: inbox.account, phone_number: '+5511988887777', blocked: true)
    create(:contact_inbox, contact: contact, inbox: inbox, source_id: '5511988887777')

    expect(dispatch).to eq(:ignored)
    expect(activity_lines).to be_empty
  end

  # A call WhatsApp announced without an id is still somebody ringing. It cannot be
  # deduplicated, and dropping it would silence every call that arrives that way.
  context 'when WhatsApp announced the call without an id' do
    let(:call_id) { nil }

    it 'writes it anyway' do
      expect(dispatch).to eq(:handled)
      expect(activity_lines.last.source_id).to be_nil
    end
  end

  # Every call ends, so a second line per call would say nothing an agent can act on,
  # and on an inbox that auto-rejects it would always say the same thing.
  it 'says nothing when the call ends' do
    dispatch
    terminate = model::Event.build(
      model::Events::CallTerminate.new(call_id: 'call-1', from: caller_party, reason: 'rejected')
    )

    expect { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, terminate) }.not_to change(inbox.messages, :count)
  end
end
