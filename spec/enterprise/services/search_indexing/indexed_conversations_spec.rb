require 'rails_helper'

RSpec.describe SearchIndexing::IndexedConversations do
  let(:client) { instance_double(OpenSearch::Client) }
  let(:page) { { '_scroll_id' => 'cursor', '_shards' => { 'failed' => 0 }, 'hits' => { 'hits' => [{ '_id' => '123' }] } } }

  before do
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:search).and_return(page)
    allow(client).to receive(:scroll).and_return(page.merge('hits' => { 'hits' => [] }))
    allow(client).to receive(:clear_scroll)
  end

  it 'visits bounded pages and releases the scroll after completion' do
    batches = []
    described_class.new(1).each_batch { |hits| batches << hits }
    expect(batches).to eq([[{ '_id' => '123' }]])
    expect(client).to have_received(:clear_scroll).with(scroll_id: 'cursor')
  end

  it 'rejects partial responses and still releases the scroll' do
    page['_shards']['failed'] = 1
    expect { described_class.new(1).each_batch { |_hits| nil } }.to raise_error(Searchkick::Error)
    expect(client).to have_received(:clear_scroll).with(scroll_id: 'cursor')
  end

  it 'keeps association scans inside the requested account' do
    described_class.new(1, filters: [{ term: { assignee_id: 42 } }]).each_batch { |_hits| nil }
    query = { bool: { filter: [{ term: { assignee_id: 42 } }, { term: { account_id: 1 } }] } }
    expect(client).to have_received(:search).with(hash_including(body: hash_including(query: query)))
  end

  it 'rejects unscoped scans' do
    expect { described_class.new(nil) }.to raise_error(ArgumentError, 'account_id is required')
  end
end
