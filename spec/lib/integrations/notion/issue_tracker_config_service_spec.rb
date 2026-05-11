require 'rails_helper'

RSpec.describe Integrations::Notion::IssueTrackerConfigService do
  let(:hook) { create(:integrations_hook, app_id: 'notion', access_token: 'notion_access_token') }
  let(:service) { described_class.new(hook: hook) }

  describe '#validate' do
    it 'fetches the Notion data source and returns normalized properties' do
      stub_request(:get, 'https://api.notion.com/v1/data_sources/data-source-1')
        .to_return(
          status: 200,
          body: {
            id: 'data-source-1',
            properties: {
              'Name' => { id: 'title', name: 'Name', type: 'title', title: {} },
              'Status' => { id: 'status', name: 'Status', type: 'status', status: {} },
              'Priority' => { id: 'priority', name: 'Priority', type: 'select', select: {} }
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(service.validate('data-source-1')).to eq(
        data: {
          data_source_id: 'data-source-1',
          title_property: 'Name',
          properties: [
            { name: 'Name', type: 'title' },
            { name: 'Priority', type: 'select' },
            { name: 'Status', type: 'status' }
          ]
        }
      )
    end

    it 'returns an error when the data source does not have a title property' do
      stub_request(:get, 'https://api.notion.com/v1/data_sources/data-source-1')
        .to_return(
          status: 200,
          body: {
            id: 'data-source-1',
            properties: {
              'Status' => { id: 'status', name: 'Status', type: 'status', status: {} }
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(service.validate('data-source-1')).to eq(error: 'Data source must include a title property')
    end

    it 'returns Notion API errors' do
      stub_request(:get, 'https://api.notion.com/v1/data_sources/missing-data-source')
        .to_return(
          status: 404,
          body: { object: 'error', message: 'Could not find data source' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(service.validate('missing-data-source')).to eq(
        error: { 'object' => 'error', 'message' => 'Could not find data source' }
      )
    end
  end
end
