require 'rails_helper'

RSpec.describe RoomChannel, type: :channel do
  let!(:user) { create(:user) }

  before do
    stub_connection
  end

  it 'subscribes to a stream when pubsub_token is provided' do
    subscribe(pubsub_token: user.uid)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user.uid)
  end
end
