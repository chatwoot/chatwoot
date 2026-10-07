require 'rails_helper'

RSpec.describe RoomChannel do
  let!(:contact_inbox) { create(:contact_inbox) }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:visitor_pubsub_token) { ContactInbox.generate_unique_secure_token }
  let(:visitor_token) do
    Widget::TokenService.new(payload: { source_id: 'visitor', inbox_id: web_widget.inbox.id, pubsub_token: visitor_pubsub_token }).generate_token
  end

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

  it 'subscribes a visitor without a contact when their widget token vouches for the stream' do
    subscribe(pubsub_token: visitor_pubsub_token, auth_token: visitor_token)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(visitor_pubsub_token)
  end

  it 'still tells a visitor without a contact which agents are online' do
    expect { subscribe(pubsub_token: visitor_pubsub_token, auth_token: visitor_token) }
      .to have_broadcasted_to(visitor_pubsub_token).with(hash_including(event: 'presence.update'))
  end

  it 'does not track presence for a visitor without a contact' do
    subscribe(pubsub_token: visitor_pubsub_token, auth_token: visitor_token)
    perform :update_presence

    expect(OnlineStatusTracker.get_available_contact_ids(account.id)).to be_empty
  end

  it 'rejects a stream the widget token does not vouch for' do
    expect { subscribe(pubsub_token: "account_#{account.id}", auth_token: visitor_token) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'rejects an unknown stream without a widget token' do
    expect { subscribe(pubsub_token: visitor_pubsub_token) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'ignores presence pings from a subscription that was rejected' do
    expect { subscribe(pubsub_token: visitor_pubsub_token) }.to raise_error(ActiveRecord::RecordNotFound)

    expect { perform :update_presence }.not_to raise_error
    expect(subscription).not_to have_stream_for(visitor_pubsub_token)
  end

  it 'starts tracking presence once the visitor gets a contact' do
    subscribe(pubsub_token: visitor_pubsub_token, auth_token: visitor_token)
    contact = create(:contact, account: account)
    create(:contact_inbox, contact: contact, inbox: web_widget.inbox, pubsub_token: visitor_pubsub_token)

    perform :update_presence

    expect(OnlineStatusTracker.get_presence(account.id, 'Contact', contact.id)).to be_truthy
  end
end
