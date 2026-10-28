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
