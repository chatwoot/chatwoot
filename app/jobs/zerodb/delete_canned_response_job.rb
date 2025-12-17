# frozen_string_literal: true

module Zerodb
  # Background job for deleting canned responses from ZeroDB index
  # Enqueued when canned responses are destroyed
  class DeleteCannedResponseJob < ApplicationJob
    queue_as :low
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    # Delete a canned response from ZeroDB vector database
    # @param canned_response_id [Integer] ID of the canned response
    # @param account_id [Integer] ID of the account
    # @param short_code [String] Short code of the canned response (for logging)
    def perform(canned_response_id, account_id, short_code = nil)
      # Create a temporary object with the necessary attributes for deletion
      temp_response = OpenStruct.new(
        id: canned_response_id,
        account_id: account_id,
        short_code: short_code
      )

      suggester = Zerodb::CannedResponseSuggester.new(account_id)
      suggester.delete_response(temp_response)

      Rails.logger.info("Successfully deleted canned response #{canned_response_id} from ZeroDB")
    rescue Zerodb::BaseService::ZeroDBError => e
      Rails.logger.error("ZeroDB API error deleting canned response #{canned_response_id}: #{e.message}")
      raise
    rescue StandardError => e
      Rails.logger.error("Failed to delete canned response #{canned_response_id}: #{e.message}")
      raise
    end
  end
end
