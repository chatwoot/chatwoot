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

    def add_document_loader(store_id:, loader_id:, splitter_id:, name:, content:)
      body = build_document_store_body(store_id, loader_id, splitter_id: splitter_id, name: name, content: content)

      save_loader = post(
        '/document-store/loader/save',
        body: body,
        headers: headers
      )

      raise "Error adding document loader: #{save_loader.code} #{save_loader.message}" unless save_loader.success?

      process_loader = post(
        "/document-store/loader/process/#{save_loader['id']}",
        body: body,
        headers: headers
      )

      raise "Error adding document loader: #{process_loader.code} #{process_loader.message}" unless process_loader.success?

      process_loader.parsed_response
    rescue StandardError => e
      Rails.logger.error("Failed to add document loader: #{e.message}")
      raise
    end

    def delete_document_loader(store_id:, loader_id:)
      response = delete("/document-store/loader/#{store_id}/#{loader_id}", headers: headers)
      raise "Error deleting document loader: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    private

    def build_document_store_body(store_id, loader_id, splitter_id:, name:, content:)
      specific_loader_config = specific_loader_config(loader_id, content)

      body = {
        'loaderId' => loader_id,
        'storeId' => store_id,
        'loaderName' => name,
        'loaderConfig' => {
          'textSplitter' => '',
          'metadata' => {}.to_json,
          'omitMetadataKeys' => ''
        }.merge(specific_loader_config)
      }

      if splitter_id.present?
        specific_splitter_name = specific_splitter_name(splitter_id)

        body.merge!(
          'splitterId' => splitter_id,
          'splitterConfig' => {
            'chunkSize' => 1000,
            'chunkOverlap' => 200
          },
          'splitterName' => specific_splitter_name
        )
      end

      body.to_json
    end

    def specific_loader_config(loader_id, content)
      case loader_id
      when 'plainText'
        { 'text' => content }
      when 'pdfFile'
        {
          'pdfFile' => content,
          'usage' => 'perPage',
          'legacyBuild' => ''
        }
      when 'htmlFile'
        { 'htmlFile' => content }
      else
        raise ArgumentError, "Unknown loader_id: #{loader_id}"
      end
    end

    def specific_splitter_name(splitter_id)
      splitter_map = {
        'htmlToMarkdownTextSplitter' => 'HtmlToMarkdown Text Splitter',
        'recursiveCharacterTextSplitter' => 'Recursive Character Text Splitter',
        'markdownTextSplitter' => 'Markdown Text Splitter'
      }

      splitter_map[splitter_id] || raise(ArgumentError, "Unknown splitter_id: #{splitter_id}")
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
{
  'loaderId': 'plainText',
  'storeId': 'e0ce4608-3645-4b05-8293-63729b1b4d68',
  'loaderName': 'Fixing run payroll untuk status karyawan bukan pegawai',
  'loaderConfig': {
    'text': 'Fixing run payroll untuk status karyawan bukan pegawai',
    'textSplitter': '',
    'metadata': '',
    'omitMetadataKeys': ''
  }
}
