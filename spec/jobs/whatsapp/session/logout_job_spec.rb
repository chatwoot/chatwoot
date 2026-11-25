require 'rails_helper'

RSpec.describe Whatsapp::Session::LogoutJob do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

  before do
    allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend)
    # The quarantine is the whole reason this job is ever enqueued.
    channel.update_provider_connection!({ 'connection' => 'close', 'error_code' => 'wrong_phone_number' })
  end

  it 'asks the session to end' do
    described_class.perform_now(channel)

    expect(backend.commands_of('session.logout').size).to eq(1)
  end

  # The caller has already written the refusal, so a repeat of the same event reports as
  # unchanged and never reaches the logout again: swallowing a transient failure would
  # leave the wrong WhatsApp account connected with nobody asking it to stop.
  it 'lets a transient failure out so the retry can see it' do
    allow(backend).to receive(:logout).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)

    expect { described_class.new.perform(channel) }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
  end

  # Publishing the logout says nothing about whether it landed: the connector answers a
  # teardown it could not carry out on the event stream, and a socket that is between
  # reconnects refuses it at once. The wrong account's first logout lands in exactly that
  # window, right after the pairing, so a single send leaves it linked.
  it 'sends the logout again later, while nothing says it landed' do
    freeze_time do
      described_class.perform_now(channel)

      expect(described_class).to have_been_enqueued.with(channel, attempt: 2)
      expect(enqueued_jobs.last[:at]).to be > Time.current.to_f
    end
  end

  it 'stands down once the account it was sent to remove has been unlinked' do
    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(
      Whatsapp::Session::Model::ConnectionState.new(connection: 'close', error: 'logged_out_by_request')
    )
    clear_enqueued_jobs

    described_class.perform_now(channel)

    expect(backend.commands_of('session.logout')).to be_empty
    expect(described_class).not_to have_been_enqueued
  end

  it 'says so when the last wait passes with nothing saying the logout landed' do
    allow(Rails.logger).to receive(:warn)

    described_class.perform_now(channel, attempt: described_class::WAITS.size + 1)

    expect(backend.commands_of('session.logout')).to be_empty
    expect(described_class).not_to have_been_enqueued
    expect(Rails.logger).to have_received(:warn).with(a_string_including("inbox #{channel.inbox.id}", 'logout'))
  end

  # Uazapi's logout is a disconnect and leaves the account on the instance, so nothing
  # would ever say it landed, and repeating it only disconnects the same account again.
  it 'sends it once to a provider whose logout cannot unpair' do
    allow(backend.class).to receive(:unpairs?).and_return(false)

    described_class.perform_now(channel)

    expect(backend.commands_of('session.logout').size).to eq(1)
    expect(described_class).not_to have_been_enqueued
  end

  it 'gives up on a failure no retry can fix' do
    allow(backend).to receive(:logout).and_raise(Whatsapp::Session::Errors::NotSupported)

    expect { described_class.new.perform(channel) }.not_to raise_error
  end

  # A retry of this job can run minutes after the rejection that queued it. By then the
  # administrator may have corrected the number and paired again, and logging out would
  # kill the session that replaced the one this was sent to remove.
  it 'does nothing once the inbox is no longer disowned' do
    channel.update_provider_connection!({ 'connection' => 'open', 'phone_number' => '5541988887777' })

    described_class.perform_now(channel)

    expect(backend.commands_of('session.logout')).to be_empty
  end
end
