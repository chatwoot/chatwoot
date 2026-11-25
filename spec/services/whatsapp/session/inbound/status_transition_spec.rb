require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::StatusTransition do
  let(:message) { create(:message, status: :sent) }

  it 'moves a message forward' do
    expect(described_class.apply(message, 'delivered')).to be(true)
    expect(message.reload.status).to eq('delivered')
  end

  it 'treats a played voice note as read' do
    expect(described_class.apply(message, 'played')).to be(true)
    expect(message.reload.status).to eq('read')
  end

  it 'never walks a status back' do
    message.update!(status: :read)

    expect(described_class.apply(message, 'delivered')).to be(false)
    expect(message.reload.status).to eq('read')
  end

  # `external_error` lives in the content_attributes JSON, so writing it through the
  # instance this held before the delete endpoint ran rewrites the whole hash and
  # undeletes the message.
  it 'keeps a flag a concurrent writer added while it held the message' do
    stale = Message.find(message.id)
    Message.find(message.id).update!(content_attributes: { 'deleted' => true })

    expect(described_class.apply(stale, 'failed', error: 'recipient unreachable')).to be(true)

    expect(stale.reload.content_attributes).to include('deleted' => true, 'external_error' => 'recipient unreachable')
  end

  # Two receipts for one message can be processed at the same time. Reading the status
  # outside the lock let both pass the check against the same old value, and the slower
  # `delivered` write then landed on top of `read`, which is the one thing the monotonic
  # rule exists to prevent.
  it 'does not walk a status backwards when two receipts race' do
    first = Message.find(message.id)
    second = Message.find(message.id)

    expect(described_class.apply(first, 'read')).to be(true)
    expect(described_class.apply(second, 'delivered')).to be(false)

    expect(message.reload.status).to eq('read')
  end

  it 'ignores a receipt type it does not know' do
    expect(described_class.apply(message, 'teleported')).to be(false)
  end

  it 'keeps the provider reason on a failure' do
    error = Whatsapp::Session::Model::WireError.new(code: 'media_too_large', message: 'file is too big')

    expect(described_class.apply(message, 'failed', error: error)).to be(true)
    expect(message.reload.status).to eq('failed')
    expect(message.external_error).to eq('file is too big media_too_large')
  end

  # The asymmetry with the failure rules below, and it is deliberate. A failure is a
  # verdict: ours when we stopped waiting on a send (which says nothing about what
  # WhatsApp did with it), the provider's about ONE attempt otherwise — and with a
  # caller-reserved id every attempt carries the same key, so a NACK on the first and a
  # delivery on the second describe the same message. A receipt is proof, and proof wins.
  # Leaving it failed keeps a resend button on a message the customer already has, which
  # is how a stalled send turns into a duplicate days later.
  it 'promotes a failed message when a receipt proves it arrived' do
    message.update!(status: :failed, external_error: 'send timed out')

    expect(described_class.apply(message, 'delivered')).to be(true)
    expect(message.reload.status).to eq('delivered')
    expect(message.external_error).to be_blank
  end

  it 'refuses to fail a message twice' do
    message.update!(status: :failed, external_error: 'send timed out')

    expect(described_class.apply(message, 'failed', error: 'send timed out again')).to be(false)
    expect(message.reload.external_error).to eq('send timed out')
  end

  # Receipts arrive out of order, so a failure can land after the read that followed a
  # later retry. Letting it through would tell the agent a message the contact already
  # read never arrived.
  it 'does not fail a message the contact already read' do
    message.update!(status: :read)

    expect(described_class.apply(message, 'failed', error: 'boom')).to be(false)
    expect(message.reload.status).to eq('read')
    expect(message.external_error).to be_blank
  end

  # Delivery is proof the message arrived, so a failure reported afterwards belongs to
  # an earlier attempt of the same send.
  it 'does not fail a message already delivered' do
    message.update!(status: :delivered)

    expect(described_class.apply(message, 'failed', error: 'boom')).to be(false)
    expect(message.reload.status).to eq('delivered')
  end

  it 'has nothing to say about a second failure' do
    message.update!(status: :failed, external_error: 'first')

    expect(described_class.apply(message, 'failed', error: 'second')).to be(false)
    expect(message.reload.external_error).to eq('first')
  end
end
