require 'rails_helper'

RSpec.describe Whatsapp::Session::TeardownRetry do
  let(:model) { Whatsapp::Session::Model }
  let(:session_id) { SecureRandom.uuid }

  def failed(command_type, code)
    model::Event.build(
      model::Events::CommandFailed.new(command_id: SecureRandom.uuid, command_type: command_type, message_id: nil,
                                       error: model::WireError.new(code: code, message: 'socket busy dialling')),
      sid: session_id, epoch: 1, seq: 1
    )
  end

  after { Redis::Alfred.delete(described_class.attempts_key(session_id, 'session.delete')) }

  # The contract's own instruction: `not_attempted` is the connector certain that nothing
  # reached WhatsApp, and a client that treats it as final leaves a device linked that no
  # later command can remove.
  it 'sends a teardown the connector never attempted again, after a wait' do
    freeze_time do
      expect(described_class.consider(failed('session.delete', 'not_attempted'))).to be(true)

      expect(Whatsapp::Session::TeardownRetryJob).to have_been_enqueued.with(session_id, 'session.delete')
      expect(enqueued_jobs.last[:at]).to eq((Time.current + described_class::WAITS.first).to_f)
    end
  end

  it 'covers the logout half of the teardown too' do
    expect(described_class.consider(failed('session.logout', 'not_attempted'))).to be(true)

    expect(Whatsapp::Session::TeardownRetryJob).to have_been_enqueued.with(session_id, 'session.logout')
  ensure
    Redis::Alfred.delete(described_class.attempts_key(session_id, 'session.logout'))
  end

  # `retryable?` is true for the whole ProviderUnavailable family, `session_not_found`
  # included, which for a teardown means it is already done. The contract singles out one
  # answer as the one to send again.
  it 'leaves every other failure of a teardown alone' do
    %w[invalid_payload session_not_found timeout internal].each do |code|
      expect(described_class.consider(failed('session.delete', code))).to be(false)
    end

    expect(Whatsapp::Session::TeardownRetryJob).not_to have_been_enqueued
  end

  it 'is only about teardowns' do
    expect(described_class.consider(failed('message.send', 'not_attempted'))).to be(false)

    expect(Whatsapp::Session::TeardownRetryJob).not_to have_been_enqueued
  end

  it 'waits longer each time the same teardown comes back unattempted' do
    freeze_time do
      2.times { described_class.consider(failed('session.delete', 'not_attempted')) }

      expect(enqueued_jobs.pluck(:at)).to eq(described_class::WAITS.first(2).map { |wait| (Time.current + wait).to_f })
    end
  end

  # The consumer runs the event again when the enqueue raises. Counting first would spend
  # the whole budget on retries that never went out, and then give up on the delivery
  # that could have worked.
  it 'spends none of the budget on a retry it could not queue' do
    allow(Whatsapp::Session::TeardownRetryJob).to receive(:set).and_raise(RedisClient::ConnectionError)

    3.times do
      expect { described_class.consider(failed('session.delete', 'not_attempted')) }.to raise_error(RedisClient::ConnectionError)
    end

    expect(Redis::Alfred.get(described_class.attempts_key(session_id, 'session.delete')).to_i).to eq(0)
  end

  it 'gives up out loud once every wait has been spent' do
    allow(Rails.logger).to receive(:warn)
    described_class::WAITS.size.times { described_class.consider(failed('session.delete', 'not_attempted')) }
    clear_enqueued_jobs

    expect(described_class.consider(failed('session.delete', 'not_attempted'))).to be(false)

    expect(Whatsapp::Session::TeardownRetryJob).not_to have_been_enqueued
    expect(Rails.logger).to have_received(:warn).with(a_string_including(session_id, 'session.delete', 'linked'))
  end

  it 'forgets the count a while after the last attempt, so a teardown asked for another day starts over' do
    described_class.consider(failed('session.delete', 'not_attempted'))

    expect(Redis::Alfred.ttl(described_class.attempts_key(session_id, 'session.delete')))
      .to be_between(described_class::WAITS.last.to_i, described_class::ATTEMPTS_TTL.to_i)
  end

  # Disconnect, run out of retries, pair again, disconnect again: the second teardown is
  # its own, and inheriting the first one's spent budget would give up on its first answer.
  it 'starts the attempts over for a teardown asked for again' do
    described_class::WAITS.size.times { described_class.consider(failed('session.delete', 'not_attempted')) }
    clear_enqueued_jobs

    described_class.requested(session_id)

    expect(described_class.consider(failed('session.delete', 'not_attempted'))).to be(true)
    expect(Whatsapp::Session::TeardownRetryJob).to have_been_enqueued.once
  ensure
    described_class.withdrawn(session_id)
  end

  it 'says in the log which answer it acted on' do
    allow(Rails.logger).to receive(:info)

    described_class.consider(failed('session.delete', 'not_attempted'))

    expect(Rails.logger).to have_received(:info).with(a_string_including(session_id, 'session.delete', 'not attempted'))
  end
end
