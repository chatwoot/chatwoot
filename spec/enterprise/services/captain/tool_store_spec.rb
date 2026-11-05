require 'rails_helper'

RSpec.describe Captain::ToolStore do
  let(:conversation) { create(:conversation) }
  let(:store) { described_class.new(conversation, 'install-1', 'jane@example.com') }

  it 'reads back what was written' do
    store.write('customer_id', %w[cus_1 cus_2])

    expect(store.read('customer_id')).to eq(%w[cus_1 cus_2])
  end

  it 'replaces earlier values for the same name' do
    store.write('customer_id', ['cus_1'])
    store.write('customer_id', ['cus_2'])

    expect(store.read('customer_id')).to eq(['cus_2'])
  end

  it 'keeps at most 20 values for a name, the first ones returned' do
    store.write('invoice_id', (1..25).map { |n| "in_#{n}" })

    expect(store.read('invoice_id')).to eq((1..20).map { |n| "in_#{n}" })
  end

  it 'reads nothing for a name that was never written' do
    expect(store.read('customer_id')).to eq([])
  end

  it 'keeps values to the conversation, the toolset installation and the name' do
    store.write('customer_id', ['cus_1'])

    expect(described_class.new(create(:conversation), 'install-1', 'jane@example.com').read('customer_id')).to eq([])
    expect(described_class.new(conversation, 'install-2', 'jane@example.com').read('customer_id')).to eq([])
    expect(store.read('subscription_id')).to eq([])
  end

  it 'ignores values found for another verified email' do
    store.write('customer_id', ['cus_1'])

    expect(described_class.new(conversation, 'install-1', 'bob@example.com').read('customer_id')).to eq([])
  end

  it 'expires the values with the verification' do
    store.write('customer_id', ['cus_1'])
    key = format(Redis::RedisKeys::CAPTAIN_TOOL_STORE, conversation_id: conversation.id, namespace: 'install-1', name: 'customer_id')

    expect(Redis::Alfred.ttl(key)).to be_between(1, Captain::EmailVerification::VERIFIED_TTL.to_i)
  end
end
