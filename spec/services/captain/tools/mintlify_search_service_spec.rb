# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::MintlifySearchService, type: :service do
  let(:assistant) { create(:captain_assistant) }
  let(:service) { described_class.new(assistant) }
  let(:mock_mcp_service) { instance_double(McpClientService) }

  before do
    allow(McpClientService).to receive(:instance).and_return(mock_mcp_service)
    # Skip sleep in tests
    allow(service).to receive(:sleep)
  end

  describe '#name' do
    it 'returns the correct tool name' do
      expect(service.name).to eq('mintlify_docs_search')
    end
  end

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to include('Search Chatwoot documentation')
    end
  end

  describe '#parameters' do
    it 'returns correct parameter schema' do
      params = service.parameters

      expect(params[:type]).to eq('object')
      expect(params[:properties][:query]).to be_present
      expect(params[:required]).to include('query')
    end
  end

  describe '#execute' do
    let(:valid_arguments) { { 'query' => 'How to setup webhooks?' } }
    let(:mock_response) do
      {
        'content' => [
          { 'type' => 'text', 'text' => 'Webhook setup documentation content here' }
        ]
      }
    end

    context 'with valid arguments' do
      it 'returns formatted documentation results' do
        # Mock iterative search - expects multiple calls
        expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(mock_response, nil, nil)

        result = service.execute(valid_arguments)

        expect(result).to include('Documentation Search Results')
        expect(result).to include('Webhook setup documentation content here')
        expect(result).to include('Source: [Chatwoot Developer Documentation]')
      end

      it 'handles different content structures' do
        string_response = { 'content' => 'Simple string content' }
        # Mock all 3 calls that the iterative search makes
        expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(string_response, nil, nil)

        result = service.execute(valid_arguments)
        expect(result).to include('Simple string content')
      end
    end

    context 'with invalid arguments' do
      it 'raises ArgumentError for missing query' do
        expect { service.execute({}) }.to raise_error(ArgumentError, 'query is required')
      end

      it 'raises ArgumentError for blank query' do
        expect { service.execute({ 'query' => '' }) }.to raise_error(ArgumentError, 'query is required')
      end
    end

    context 'when MCP service fails' do
      it 'handles timeout errors gracefully' do
        allow(mock_mcp_service).to receive(:call_tool)
          .and_raise(McpClientService::TimeoutError.new('Request timed out'))

        result = service.execute(valid_arguments)
        expect(result).to include('search timed out')
      end

      it 'handles connection errors gracefully' do
        allow(mock_mcp_service).to receive(:call_tool)
          .and_raise(McpClientService::ConnectionError.new('Connection failed'))

        result = service.execute(valid_arguments)
        expect(result).to include('temporarily unavailable')
      end

      it 'handles configuration errors gracefully' do
        allow(mock_mcp_service).to receive(:call_tool)
          .and_raise(McpClientService::ConfigurationError.new('Bad config'))

        result = service.execute(valid_arguments)
        expect(result).to include('not properly configured')
      end

      it 'handles unexpected errors gracefully' do
        allow(mock_mcp_service).to receive(:call_tool)
          .and_raise(StandardError.new('Unexpected error'))

        result = service.execute(valid_arguments)
        expect(result).to include('encountered an error')
      end
    end

    context 'when no results found' do
      it 'returns no results message for empty response' do
        allow(mock_mcp_service).to receive(:call_tool).and_return(nil)

        result = service.execute(valid_arguments)
        expect(result).to include("couldn't find relevant information")
      end

      it 'returns no results message for empty content' do
        empty_response = { 'content' => [] }
        allow(mock_mcp_service).to receive(:call_tool).and_return(empty_response)

        result = service.execute(valid_arguments)
        expect(result).to include("couldn't find relevant information")
      end
    end
  end

  describe '#active?' do
    context 'when MCP client is available' do
      before do
        allow(mock_mcp_service).to receive(:client_for).with('mintlify').and_return(instance_double(MCPClient))
      end

      it 'returns true' do
        expect(service.active?).to be true
      end
    end

    context 'when MCP client is not available' do
      before do
        allow(mock_mcp_service).to receive(:client_for).with('mintlify').and_return(nil)
      end

      it 'returns false' do
        expect(service.active?).to be false
      end
    end

    context 'when MCP service raises an error' do
      before do
        allow(mock_mcp_service).to receive(:client_for).and_raise(StandardError.new('Service error'))
      end

      it 'returns false and logs debug message' do
        expect(Rails.logger).to receive(:debug)
        expect(service.active?).to be false
      end
    end
  end

  describe '#health_check' do
    context 'when service is healthy' do
      before do
        allow(service).to receive(:active?).and_return(true)
        allow(mock_mcp_service).to receive(:client_for).with('mintlify').and_return(instance_double(MCPClient))
      end

      it 'returns healthy status with details' do
        health = service.health_check

        expect(health[:status]).to eq('healthy')
        expect(health[:client_available]).to be true
        expect(health[:last_check]).to be_present
      end
    end

    context 'when service has errors' do
      before do
        allow(service).to receive(:active?).and_raise(StandardError.new('Service error'))
      end

      it 'returns error status' do
        health = service.health_check

        expect(health[:status]).to eq('error')
        expect(health[:error]).to eq('Service error')
        expect(health[:last_check]).to be_present
      end
    end
  end

  describe 'content extraction' do
    let(:valid_arguments) { { 'query' => 'test query' } }

    it 'extracts text from array of content blocks' do
      array_response = {
        'content' => [
          { 'type' => 'text', 'text' => 'First block' },
          { 'type' => 'text', 'text' => 'Second block' }
        ]
      }

      # Mock all 3 calls from iterative search
      expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(array_response, nil, nil)

      result = service.execute(valid_arguments)
      expect(result).to include('First block')
      expect(result).to include('Second block')
    end

    it 'extracts text from hash content block' do
      hash_response = {
        'content' => { 'type' => 'text', 'text' => 'Single block content' }
      }

      expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(hash_response, nil, nil)

      result = service.execute(valid_arguments)
      expect(result).to include('Single block content')
    end

    it 'handles string content directly' do
      string_response = { 'content' => 'Direct string content' }

      expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(string_response, nil, nil)

      result = service.execute(valid_arguments)
      expect(result).to include('Direct string content')
    end

    it 'handles blocks with different structures' do
      mixed_response = {
        'content' => [
          { 'text' => 'Text without type' },
          { 'type' => 'other', 'value' => 'Other content' }
        ]
      }

      expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(mixed_response, nil, nil)

      result = service.execute(valid_arguments)
      expect(result).to include('Text without type')
    end
  end

  describe 'iterative search behavior' do
    let(:valid_arguments) { { 'query' => 'API integration' } }

    it 'performs multiple searches for comprehensive results' do
      responses = [
        { 'content' => 'Main API information' },
        { 'content' => 'Authentication details' },
        { 'content' => 'Examples and endpoints' }
      ]

      expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(*responses)

      result = service.execute(valid_arguments)

      expect(result).to include('Main API information')
      expect(result).to include('Authentication details')
      expect(result).to include('Examples and endpoints')
      expect(result).to include('3 searches combined')
    end

    it 'handles failed searches gracefully' do
      expect(mock_mcp_service).to receive(:call_tool).exactly(3).times
                                                     .and_return(nil, { 'content' => 'Some content' }, nil)

      result = service.execute(valid_arguments)
      expect(result).to include('Some content')
    end

    it 'stops early if no results found' do
      expect(mock_mcp_service).to receive(:call_tool).exactly(3).times.and_return(nil, nil, nil)

      result = service.execute(valid_arguments)
      expect(result).to include("couldn't find relevant information")
    end
  end
end