# frozen_string_literal: true

module Zerodb
  # Service to provision AINative/ZeroDB projects for Chatwoot accounts
  # Creates a dedicated project per account with appropriate configuration
  class ProjectProvisionService
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    TIMEOUT = 30
    MAX_RETRIES = 3
    RETRY_DELAY = 1

    class ProvisionError < StandardError; end
    class ProjectLimitError < ProvisionError; end
    class AuthenticationError < ProvisionError; end

    def initialize(account)
      @account = account
      @master_api_key = ENV.fetch('ZERODB_MASTER_API_KEY', nil)
      validate_configuration!
    end

    # Provision a new AINative project for the account
    # @return [Hash] Project details including project_id and api_key
    def provision!
      return existing_project_details if @account.ainative_configured?

      project = create_project
      update_account(project)
      configure_project_features(project)

      {
        project_id: project['id'],
        project_name: project['name'],
        api_key: project['api_key']
      }
    rescue StandardError => e
      Rails.logger.error("[ZeroDB::ProjectProvision] Failed to provision project for account #{@account.id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise ProvisionError, "Failed to provision AINative project: #{e.message}"
    end

    # Deprovision (delete) the AINative project for this account
    def deprovision!
      return unless @account.ainative_configured?

      delete_project(@account.ainative_project_id)
      clear_account_ainative_data

      Rails.logger.info("[ZeroDB::ProjectProvision] Deprovisioned project #{@account.ainative_project_id} for account #{@account.id}")
    rescue StandardError => e
      Rails.logger.error("[ZeroDB::ProjectProvision] Failed to deprovision project for account #{@account.id}: #{e.message}")
      raise ProvisionError, "Failed to deprovision AINative project: #{e.message}"
    end

    private

    def validate_configuration!
      return if @master_api_key.present?

      raise AuthenticationError, 'ZERODB_MASTER_API_KEY environment variable is not set'
    end

    def existing_project_details
      {
        project_id: @account.ainative_project_id,
        project_name: @account.name,
        api_key: @account.ainative_api_key_encrypted
      }
    end

    def create_project
      response = self.class.post(
        '/projects',
        headers: master_headers,
        body: project_payload.to_json,
        timeout: TIMEOUT
      )

      handle_response(response, :create)
    end

    def delete_project(project_id)
      response = self.class.delete(
        "/projects/#{project_id}",
        headers: master_headers,
        timeout: TIMEOUT
      )

      handle_response(response, :delete)
    end

    def configure_project_features(project)
      # Enable semantic search, vector storage, and agent memory features
      features_payload = {
        features: {
          semantic_search: true,
          vector_storage: true,
          agent_memory: true,
          rlhf_collection: true
        }
      }

      response = self.class.patch(
        "/projects/#{project['id']}/settings",
        headers: project_headers(project['api_key']),
        body: features_payload.to_json,
        timeout: TIMEOUT
      )

      handle_response(response, :configure)
    rescue StandardError => e
      Rails.logger.warn("[ZeroDB::ProjectProvision] Failed to configure features for project #{project['id']}: #{e.message}")
      # Non-fatal - project is still created
    end

    def update_account(project)
      @account.update!(
        ainative_project_id: project['id'],
        ainative_api_key_encrypted: project['api_key'],
        ainative_settings: default_ainative_settings
      )

      Rails.logger.info("[ZeroDB::ProjectProvision] Provisioned project #{project['id']} for account #{@account.id}")
    end

    def clear_account_ainative_data
      @account.update!(
        ainative_project_id: nil,
        ainative_api_key_encrypted: nil
      )
    end

    def project_payload
      {
        name: "chatwoot-#{@account.id}-#{@account.name.parameterize}",
        description: "Chatwoot account: #{@account.name}",
        settings: {
          embeddings_model: 'BAAI/bge-small-en-v1.5',
          vector_dimensions: 384
        },
        metadata: {
          chatwoot_account_id: @account.id,
          chatwoot_account_name: @account.name,
          created_via: 'auto_provision'
        }
      }
    end

    def default_ainative_settings
      {
        embeddings_model: 'BAAI/bge-small-en-v1.5',
        vector_dimensions: 384,
        auto_indexing: true,
        features: {
          semantic_search: true,
          smart_suggestions: true,
          agent_memory: true
        }
      }
    end

    def master_headers
      {
        'Authorization' => "Bearer #{@master_api_key}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    def project_headers(api_key)
      {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    def handle_response(response, action)
      case response.code
      when 200, 201
        response.parsed_response
      when 401, 403
        raise AuthenticationError, "Authentication failed: #{response.body}"
      when 429
        raise ProjectLimitError, "Project limit reached: #{response.parsed_response['detail']}"
      when 400, 422
        raise ProvisionError, "Invalid request: #{response.body}"
      else
        raise ProvisionError, "API request failed (#{response.code}): #{response.body}"
      end
    rescue JSON::ParserError
      raise ProvisionError, "Invalid API response: #{response.body}"
    end
  end
end
