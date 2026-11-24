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
end
