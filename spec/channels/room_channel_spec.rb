require 'rails_helper'

RSpec.describe RoomChannel do
  let!(:contact_inbox) { create(:contact_inbox) }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  before do
    stub_connection
  end

  it 'subscribes to a stream when pubsub_token is provided' do
    subscribe(pubsub_token: contact_inbox.pubsub_token)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(contact_inbox.pubsub_token)
  end

  it 'subscribes to a stream when pubsub_token is provided for user' do
    subscribe(user_id: user.id, pubsub_token: user.pubsub_token, account_id: account.id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user.pubsub_token)
    expect(subscription).to have_stream_for("account_#{account.id}")
    expect(subscription).to have_stream_for(described_class.account_user_stream(account.id, user.id))
  end

  it 'closes the connection once the user is removed from the account' do
    handlers = {}
    allow(described_class).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap do |channel|
        allow(channel).to receive(:stream_from) { |broadcasting, &handler| handlers[broadcasting] = handler }
      end
    end
    closed_with = nil
    connection.define_singleton_method(:close) { |**options| closed_with = options }

    subscribe(user_id: user.id, pubsub_token: user.pubsub_token, account_id: account.id)
    handlers.fetch(described_class.account_user_stream(account.id, user.id)).call({ event: 'account_user.removed' }.to_json)

    expect(closed_with).to eq(reason: 'unauthorized')
  end

  it 'does not subscribe a user to an account they no longer belong to' do
    user.account_users.find_by(account: account).destroy!

    expect { subscribe(user_id: user.id, pubsub_token: user.pubsub_token, account_id: account.id) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'sends the agent their work preferences with presence' do
    user.account_users.find_by(account: account).update!(accepts_calls: false)

    expect { subscribe(user_id: user.id, pubsub_token: user.pubsub_token, account_id: account.id) }
      .to have_broadcasted_to(user.pubsub_token).with(
        hash_including(data: hash_including(work_preferences: { 'accepts_conversations' => true, 'accepts_calls' => false }))
      )
  end

  it 'does not send work preferences to a contact' do
    expect { subscribe(pubsub_token: contact_inbox.pubsub_token) }
      .to have_broadcasted_to(contact_inbox.pubsub_token).with(hash_including(data: hash_excluding(:work_preferences)))
  end
end
