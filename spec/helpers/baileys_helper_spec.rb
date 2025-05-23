require 'rails_helper'

RSpec.describe BaileysHelper do
  let(:timestamp) { 1_748_003_165 }
  let(:timestamp_hash) { { 'low' => timestamp, 'high' => 123, 'unsigned' => true } }

  it 'extracts the timestamp from a string' do
    expect(extract_baileys_message_timestamp(timestamp.to_s)).to eq(timestamp)
  end

  it 'extracts the timestamp from an int' do
    expect(extract_baileys_message_timestamp(timestamp)).to eq(timestamp)
  end

  it 'extracts the timestamp from a hash' do
    expected_timestamp = timestamp + (timestamp_hash['high'] << 32)

    expect(extract_baileys_message_timestamp(timestamp_hash)).to eq(expected_timestamp)
  end
end
