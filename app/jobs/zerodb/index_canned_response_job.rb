# frozen_string_literal: true

module Zerodb
  # Background job for indexing canned responses to ZeroDB
  # Enqueued when canned responses are created or updated
  class IndexCannedResponseJob < ApplicationJob
    queue_as :low
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    # Index a canned response to ZeroDB vector database
    # @param canned_response_id [Integer] ID of the canned response to index
    # @param account_id [Integer] ID of the account owning the canned response
    def perform(canned_response_id, account_id)
      canned_response = CannedResponse.find_by(id: canned_response_id, account_id: account_id)

      unless canned_response
        Rails.logger.warn("CannedResponse #{canned_response_id} not found for account #{account_id}")
        return
      end

      suggester = Zerodb::CannedResponseSuggester.new(account_id)
      suggester.index_response(canned_response)

      Rails.logger.info("Successfully indexed canned response #{canned_response_id} in ZeroDB")
    rescue Zerodb::BaseService::ZeroDBError => e
      Rails.logger.error("ZeroDB API error indexing canned response #{canned_response_id}: #{e.message}")
      raise
    rescue StandardError => e
      Rails.logger.error("Failed to index canned response #{canned_response_id}: #{e.message}")
      raise
    end
  end
end
