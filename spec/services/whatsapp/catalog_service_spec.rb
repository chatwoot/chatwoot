require 'rails_helper'

describe Whatsapp::CatalogService do
  subject(:result) { described_class.new(channel: channel).perform }

  let(:graph) { 'https://graph.facebook.com/v22.0' }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:fields) { 'retailer_id,name,description,price,image_url,additional_image_urls,url,product_sets{id,name}' }
  let(:all_products) { { 'id' => 'set_all', 'name' => 'All Products' } }
  let(:sets) do
    [{ 'id' => 'set_all', 'name' => 'All Products', 'product_count' => 3 },
     { 'id' => 'set_1', 'name' => 'Set 1', 'product_count' => 1 },
     { 'id' => 'set_2', 'name' => 'Set 2', 'product_count' => 2 }]
  end
  let(:product_a) do
    { 'retailer_id' => 'a', 'name' => 'A', 'price' => '$ 5.000', 'image_url' => 'https://img/a.jpg',
      'additional_image_urls' => ['https://img/a2.jpg'], 'description' => 'da', 'url' => 'https://shop/a',
      'product_sets' => { 'data' => [all_products, { 'id' => 'set_1', 'name' => 'Set 1' }, { 'id' => 'set_2', 'name' => 'Set 2' }] } }
  end
  let(:product_c) { { 'retailer_id' => 'c', 'name' => 'C', 'price' => '$ 2.000' } }
  let(:products_args) { { limit: 24 } }

  def stub_graph(path, body, query: {}, status: 200)
    stub_request(:get, "#{graph}/#{path}").with(query: hash_including(query))
                                          .to_return(status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  before do
    stub_graph('123456789/product_catalogs', { data: [{ 'id' => 'cat_1', 'name' => 'Shop' }] })
    stub_graph('cat_1/product_sets', { data: sets }, query: { 'fields' => 'id,name,product_count' })
  end

  context 'when listing collections' do
    it 'returns collections with counts, without products and without All Products' do
      expect(result).to eq(
        status: 'ok', catalog_id: 'cat_1',
        collections: [{ id: 'set_1', name: 'Set 1', count: 1 }, { id: 'set_2', name: 'Set 2', count: 2 }]
      )
      expect(a_request(:get, %r{/products})).not_to have_been_made
    end

    context 'with a cache store' do
      before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

      it 'caches collections and the catalog id, and refresh bypasses both' do
        2.times { described_class.new(channel: channel).perform }
        expect(a_request(:get, %r{cat_1/product_sets})).to have_been_made.once
        expect(a_request(:get, /product_catalogs/)).to have_been_made.once

        described_class.new(channel: channel, refresh: '1').perform
        expect(a_request(:get, %r{cat_1/product_sets})).to have_been_made.twice
        expect(a_request(:get, /product_catalogs/)).to have_been_made.twice
      end

      it 'does not cache errors' do
        stub_graph('cat_1/product_sets', { error: { code: 1, message: 'boom' } }, status: 500)
        2.times { described_class.new(channel: channel).perform }

        expect(a_request(:get, %r{cat_1/product_sets})).to have_been_made.twice
      end
    end
  end

  context 'when catalog_id is configured' do
    before { channel.update!(provider_config: channel.provider_config.merge('catalog_id' => 'cat_9')) }

    it 'skips the product_catalogs lookup' do
      stub_graph('cat_9/product_sets', { data: [] })

      expect(result[:catalog_id]).to eq('cat_9')
      expect(a_request(:get, /product_catalogs/)).not_to have_been_made
    end
  end

  describe '#products' do
    subject(:result) { described_class.new(channel: channel).products(**products_args) }

    before { stub_graph('cat_1/products', { data: [product_a, product_c] }, query: { 'fields' => fields, 'limit' => '24' }) }

    it 'formats one page with collection ids, without All Products, and a null cursor on a short page' do
      expect(result[:status]).to eq('ok')
      expect(result[:next_cursor]).to be_nil
      expect(result[:products].first).to eq(
        retailer_id: 'a', name: 'A', price: '$ 5.000', image_urls: ['https://img/a.jpg', 'https://img/a2.jpg'],
        description: 'da', url: 'https://shop/a', collection_ids: %w[set_1 set_2]
      )
      expect(result[:products].last).to include(collection_ids: [], image_urls: [], description: nil, url: nil)
      expect(a_request(:get, %r{cat_1/products})).to have_been_made.once
    end

    context 'with a full page and a cursor' do
      let(:products_args) { { limit: 2 } }

      before do
        stub_graph('cat_1/products', { data: [product_a, product_c], paging: { cursors: { after: 'c1' }, next: 'x' } },
                   query: { 'limit' => '2' })
        stub_graph('cat_1/products', { data: [product_c], paging: { cursors: { after: 'c2' }, next: 'y' } },
                   query: { 'limit' => '2', 'after' => 'c1' })
      end

      it 'returns the Meta cursor and requests the next page with it' do
        expect(result[:next_cursor]).to eq('c1')
        page = described_class.new(channel: channel).products(limit: 2, after: 'c1')

        expect(page[:products].pluck(:retailer_id)).to eq(['c'])
        expect(page[:next_cursor]).to be_nil
      end
    end

    context 'with a text query' do
      let(:products_args) { { limit: 24, query: 'Café "ñandú"' } }

      it 'sends the filter as escaped JSON' do
        result

        filter = { name: { i_contains: 'Café "ñandú"' } }.to_json
        expect(a_request(:get, %r{cat_1/products}).with(query: hash_including('filter' => filter))).to have_been_made.once
      end
    end

    context 'with a collection' do
      let(:products_args) { { limit: 24, collection_id: 'set_1', query: 'a' } }

      before { stub_graph('set_1/products', { data: [product_a] }, query: { 'limit' => '24' }) }

      it 'reads the collection products and filters inside it' do
        expect(result[:products].pluck(:retailer_id)).to eq(['a'])
        filter = { name: { i_contains: 'a' } }.to_json
        expect(a_request(:get, %r{set_1/products}).with(query: hash_including('filter' => filter))).to have_been_made.once
        expect(a_request(:get, %r{cat_1/products})).not_to have_been_made
      end
    end

    context 'with a collection of another catalog' do
      let(:products_args) { { limit: 24, collection_id: 'foreign' } }

      it 'returns invalid_collection without reading products' do
        expect(result).to eq(status: 'invalid_collection')
        expect(a_request(:get, %r{/products})).not_to have_been_made
      end
    end

    context 'with a cache store' do
      before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

      it 'caches the first page without query and skips the cache for q and after' do
        2.times { described_class.new(channel: channel).products(limit: 24) }
        expect(a_request(:get, %r{cat_1/products})).to have_been_made.once

        2.times { described_class.new(channel: channel).products(limit: 24, query: 'a') }
        2.times { described_class.new(channel: channel).products(limit: 24, after: 'c1') }
        expect(a_request(:get, %r{cat_1/products})).to have_been_made.times(5)
      end

      it 'bypasses the cache on refresh' do
        described_class.new(channel: channel).products(limit: 24)
        described_class.new(channel: channel, refresh: '1').products(limit: 24)

        expect(a_request(:get, %r{cat_1/products})).to have_been_made.twice
      end

      it 'does not cache errors' do
        stub_graph('cat_1/products', { error: { code: 1, message: 'boom' } }, status: 500)
        2.times { described_class.new(channel: channel).products(limit: 24) }

        expect(a_request(:get, %r{cat_1/products})).to have_been_made.twice
      end
    end
  end

  context 'when the WABA has no catalog' do
    it 'returns no_catalog' do
      stub_graph('123456789/product_catalogs', { data: [] })

      expect(result).to eq(status: 'no_catalog')
    end
  end

  context 'when Meta denies permission' do
    it 'returns missing_permission' do
      stub_graph('123456789/product_catalogs', { error: { code: 200, message: 'Permissions error' } }, status: 403)

      expect(result).to eq(status: 'missing_permission')
    end
  end

  context 'when Meta fails otherwise' do
    it 'returns error' do
      stub_graph('123456789/product_catalogs', { error: { code: 1, message: 'boom' } }, status: 500)

      expect(result).to eq(status: 'error')
    end
  end
end
