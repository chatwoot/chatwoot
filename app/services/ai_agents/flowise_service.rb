require 'httparty'

class AiAgents::FlowiseService
  include HTTParty
  base_uri 'https://ai.radyalabs.id/api/v1'

  class << self
    def load_chat_flow(name:, flow_data:, is_public: false, deployed: false, type: 'CHATFLOW')
      raise ArgumentError, 'Template cannot be nil' if flow_data.nil?

      response = post(
        '/chatflows',
        body: {
          'name' => name,
          'flowData' => flow_data.to_json,
          'isPublic' => is_public,
          'deployed' => deployed,
          'type' => type
        }.to_json,
        headers: headers
      )

      raise "Error loading chat flow: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    def delete_chat_flow(id:)
      response = delete("/chatflows/#{id}", headers: headers)

      raise "Error deleting chat flow: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    def add_document_store(name:, description: 'Document Store')
      response = post(
        '/document-store/store',
        body: {
          'name' => name,
          'description' => description
        }.to_json,
        headers: headers
      )

      raise "Error adding document store: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    def add_document_loader(store_id:, name:, text:)
      body = build_document_store_body(
        store_id: store_id,
        name: name,
        text: text
      )

      save_loader = post(
        '/document-store/loader/save',
        body: body,
        headers: headers
      )
      Rails.logger.info("Save Loader Response: #{save_loader}")
      raise "Error adding document loader: #{save_loader.code} #{save_loader.message}" unless save_loader.success?

      process_loader = post(
        "/document-store/loader/process/#{save_loader['id']}",
        body: body,
        headers: headers
      )

      raise "Error adding document loader: #{process_loader.code} #{process_loader.message}" unless process_loader.success?

      process_loader.parsed_response
    end

    def delete_document_loader(store_id:, loader_id:)
      response = delete("/document-store/loader/#{store_id}/#{loader_id}", headers: headers)
      raise "Error deleting document loader: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    private

    def build_document_store_body(store_id:, name:, text:)
      {
        'loaderId' => 'plainText',
        'storeId' => store_id,
        'loaderName' => name,
        'loaderConfig' => {
          'text' => text,
          'textSplitter' => '',
          'metadata' => {}.to_json,
          'omitMetadataKeys' => ''
        },
        'splitterId' => 'htmlToMarkdownTextSplitter',
        'splitterConfig' => {
          'chunkSize' => 1000,
          'chunkOverlap' => 200
          # 'separators' => ''
        },
        'splitterName' => 'HtmlToMarkdown Text Splitter'
      }.to_json
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => 'Bearer d3YPZUOXkeq3xHy105Km7SeGerjsATPQ7M9sAFT9lSE='
      }
    end
  end
end
