require 'rails_helper'

RSpec.describe Notion do
  let(:access_token) { 'notion_access_token' }
  let(:notion_client) { described_class.new(access_token) }

  describe '#initialize' do
    it 'initializes with access token' do
      expect(notion_client.instance_variable_get(:@access_token)).to eq(access_token)
    end

    it 'raises error when access token is blank' do
      expect { described_class.new('') }.to raise_error(ArgumentError, 'Missing Credentials')
    end
  end

  describe '#search' do
    let(:query) { 'test query' }
    let(:sort) { { direction: 'ascending', timestamp: 'last_edited_time' } }
    let(:response_body) { { 'results' => [{ 'id' => '123', 'object' => 'page' }] } }
    let(:response) { instance_double(HTTParty::Response, success?: true, parsed_response: response_body) }

    before do
      allow(HTTParty).to receive(:post).and_return(response)
    end

    it 'makes a POST request to search endpoint' do
      notion_client.search(query)

      expect(HTTParty).to have_received(:post).with(
        'https://api.notion.com/v1/search',
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Notion-Version' => '2022-06-28',
          'Content-Type' => 'application/json'
        },
        body: { query: query }.to_json
      )
    end

    it 'includes sort parameters when provided' do
      notion_client.search(query, sort)

      expect(HTTParty).to have_received(:post).with(
        'https://api.notion.com/v1/search',
        headers: anything,
        body: { query: query, sort: sort }.to_json
      )
    end

    it 'returns parsed response on success' do
      result = notion_client.search(query)
      expect(result).to eq(response_body.with_indifferent_access)
    end

    context 'when request fails' do
      let(:error_response) { { 'object' => 'error', 'status' => 400 } }
      let(:failed_response) { instance_double(HTTParty::Response, success?: false, parsed_response: error_response, code: 400) }

      before do
        allow(HTTParty).to receive(:post).and_return(failed_response)
      end

      it 'returns error response' do
        result = notion_client.search(query)
        expect(result).to eq({ error: error_response, error_code: 400 })
      end
    end
  end

  describe '#page' do
    let(:page_id) { 'page-123' }
    let(:response_body) { { 'id' => page_id, 'object' => 'page' } }
    let(:response) { instance_double(HTTParty::Response, success?: true, parsed_response: response_body) }

    before do
      allow(HTTParty).to receive(:get).and_return(response)
    end

    it 'makes a GET request to pages endpoint' do
      notion_client.page(page_id)

      expect(HTTParty).to have_received(:get).with(
        "https://api.notion.com/v1/pages/#{page_id}",
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Notion-Version' => '2022-06-28',
          'Content-Type' => 'application/json'
        }
      )
    end

    it 'returns parsed response on success' do
      result = notion_client.page(page_id)
      expect(result).to eq(response_body.with_indifferent_access)
    end

    it 'raises error when page_id is blank' do
      expect { notion_client.page('') }.to raise_error(ArgumentError, 'Missing page id')
    end
  end

  describe '#page_blocks' do
    let(:page_id) { 'page-123' }
    let(:response_body) { { 'results' => [{ 'id' => 'block-1', 'type' => 'paragraph' }] } }
    let(:response) { instance_double(HTTParty::Response, success?: true, parsed_response: response_body) }

    before do
      allow(HTTParty).to receive(:get).and_return(response)
    end

    it 'makes a GET request to blocks endpoint' do
      notion_client.page_blocks(page_id)

      expect(HTTParty).to have_received(:get).with(
        "https://api.notion.com/v1/blocks/#{page_id}/children",
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Notion-Version' => '2022-06-28',
          'Content-Type' => 'application/json'
        }
      )
    end

    it 'returns parsed response on success' do
      result = notion_client.page_blocks(page_id)
      expect(result).to eq(response_body.with_indifferent_access)
    end

    it 'raises error when page_id is blank' do
      expect { notion_client.page_blocks('') }.to raise_error(ArgumentError, 'Missing page id')
    end
  end
end