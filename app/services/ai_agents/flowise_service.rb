require 'httparty'

class AiAgents::FlowiseService
  include HTTParty
  base_uri ENV.fetch('FLOWISE_API_URL', 'https://ai.radyalabs.id/api/v1')

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

    def delete_document_store(store_id:)
      response = delete("/document-store/store/#{store_id}", headers: headers)
      raise "Error deleting document store: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    def add_document_loader(store_id:, loader_id:, splitter_id:, name:, content:)
      body = document_loader_body(store_id, loader_id, splitter_id: splitter_id, name: name, content: content)

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

    def document_loader_body(store_id, loader_id, splitter_id:, name:, content:)
      body = base_body(store_id, loader_id, name, content)
      body.merge!(splitter_body(splitter_id)) if splitter_id.present?
      body.to_json
    end

    def base_body(store_id, loader_id, name, content)
      {
        'loaderId' => loader_id,
        'storeId' => store_id,
        'loaderName' => name,
        'loaderConfig' => default_loader_config.merge(specific_loader_config(loader_id, content))
      }
    end

    def default_loader_config
      {
        'textSplitter' => '',
        'metadata' => {}.to_json,
        'omitMetadataKeys' => ''
      }
    end

    def splitter_body(splitter_id)
      {
        'splitterId' => splitter_id,
        'splitterConfig' => {
          'chunkSize' => 1000,
          'chunkOverlap' => 200
        },
        'splitterName' => specific_splitter_name(splitter_id)
      }
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
        'Authorization' => "Bearer #{ENV.fetch('FLOWISE_API_KEY', nil)}"
      }
    end
  end
end
