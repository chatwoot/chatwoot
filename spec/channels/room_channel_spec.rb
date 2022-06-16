require 'rails_helper'

RSpec.describe RoomChannel, type: :channel do
  let!(:contact_inbox) { create(:contact_inbox) }

  before do
    stub_connection
  end

  it 'subscribes to a stream when pubsub_token is provided' do
    subscribe(pubsub_token: contact_inbox.pubsub_token)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(contact_inbox.pubsub_token)
  end
end
