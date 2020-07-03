require 'rails_helper'

RSpec.describe RoomChannel, type: :channel do
  let!(:contact) { create(:contact) }

  before do
    stub_connection
  end

  it 'subscribes to a stream when pubsub_token is provided' do
    subscribe(pubsub_token: contact.pubsub_token)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(contact.pubsub_token)
  end
end
