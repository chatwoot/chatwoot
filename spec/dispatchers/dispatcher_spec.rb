require 'rails_helper'

RSpec.describe Dispatcher do
  let(:dispatcher) { described_class.instance }
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:timestamp) { Time.zone.now }

  before do
    conversation
    allow(dispatcher.sync_dispatcher).to receive(:dispatch)
    allow(dispatcher.async_dispatcher).to receive(:dispatch)
  end

  after { Current.reset }

  it 'captures the authenticated user before synchronous listeners change Current' do
    Current.user = user
    data = { conversation: conversation, performed_by: nil }
    allow(dispatcher.sync_dispatcher).to receive(:dispatch) { Current.reset }

    dispatcher.dispatch('conversation.updated', timestamp, data)

    expect(dispatcher.async_dispatcher).to have_received(:dispatch).with(
      'conversation.updated', timestamp, data.merge(webhook_actor: { type: 'user', id: user.id })
    )
    expect(data).not_to have_key(:webhook_actor)
  end

  it 'keeps the explicit automation actor ahead of the request user' do
    rule = create(:automation_rule, account: account)
    Current.user = user
    data = { conversation: conversation, performed_by: rule }

    dispatcher.dispatch('conversation.status_changed', timestamp, data)

    expect(dispatcher.async_dispatcher).to have_received(:dispatch).with(
      'conversation.status_changed', timestamp, data.merge(webhook_actor: { type: 'automation_rule', id: rule.id })
    )
  end

  it 'does not fall back to the request user when an explicit actor is unsupported' do
    Current.user = user
    data = { conversation: conversation, performed_by: create(:team, account: account) }

    dispatcher.dispatch('conversation.updated', timestamp, data)

    expect(dispatcher.async_dispatcher).to have_received(:dispatch).with(
      'conversation.updated', timestamp, data.merge(webhook_actor: nil)
    )
  end

  it 'keeps the actor distinct from the message sender' do
    message = create(:message, conversation: conversation, account: account, inbox: conversation.inbox, sender: conversation.contact)
    Current.user = user
    data = { message: message, performed_by: nil }

    dispatcher.dispatch('message.created', timestamp, data)

    expect(dispatcher.async_dispatcher).to have_received(:dispatch).with(
      'message.created', timestamp, data.merge(webhook_actor: { type: 'user', id: user.id })
    )
  end

  it 'retains the captured identity through ActiveJob serialization after Current is reset' do
    Current.user = user
    data = { conversation: conversation, performed_by: nil }
    queued = nil
    allow(dispatcher.async_dispatcher).to receive(:dispatch) do |name, time, event_data|
      queued = ActiveJob::Arguments.serialize([name, time, event_data])
    end

    dispatcher.dispatch('conversation.updated', timestamp, data)
    Current.reset
    event_data = ActiveJob::Arguments.deserialize(queued).last

    expect(event_data[:webhook_actor]).to eq(type: 'user', id: user.id)
    expect(event_data[:performed_by]).to be_nil
  end

  it 'leaves unrelated events unchanged' do
    data = { contact: conversation.contact }

    dispatcher.dispatch('contact.updated', timestamp, data)

    expect(dispatcher.async_dispatcher).to have_received(:dispatch).with('contact.updated', timestamp, data)
  end
end
