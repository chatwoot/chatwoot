# frozen_string_literal: true

module Zerodb
  # RLHF (Reinforcement Learning from Human Feedback) Service
  # Collects agent feedback on AI suggestions to improve quality over time
  #
  # Supports feedback collection for:
  # - Canned response suggestions
  # - Semantic search results
  # - Any AI-generated content
  #
  # @example Logging feedback
  #   service = Zerodb::RlhfService.new(account_id: 123)
  #   service.log_feedback(
  #     suggestion_type: 'canned_response_suggestion',
  #     prompt: 'Customer asking about refund policy',
  #     response: 'Our refund policy is...',
  #     rating: 5,
  #     feedback: 'Very helpful suggestion',
  #     metadata: { conversation_id: 456 }
  #   )
  class RlhfService < BaseService
    # Valid suggestion types for RLHF feedback
    VALID_SUGGESTION_TYPES = %w[
      canned_response_suggestion
      semantic_search
      ai_assistant
      smart_reply
    ].freeze

    # Rating scale (1-5 stars)
    MIN_RATING = 1
    MAX_RATING = 5

    # Initialize RLHF service for a specific account
    # @param account_id [Integer] Account ID for data isolation
    def initialize(account_id:)
      super()
      @account_id = account_id
    end

    # Log agent feedback on AI suggestion
    # @param suggestion_type [String] Type of suggestion ('canned_response_suggestion', 'semantic_search', etc.)
    # @param prompt [String] Original user input/context
    # @param response [String] AI-generated suggestion
    # @param rating [Integer] Rating from 1-5 stars
    # @param feedback [String, nil] Optional text feedback
    # @param metadata [Hash] Additional context (conversation_id, suggestion_id, etc.)
    # @return [Hash] API response with feedback ID
    # @raise [ArgumentError] If validation fails
    # @raise [StandardError] If API request fails
    def log_feedback(suggestion_type:, prompt:, response:, rating:, feedback: nil, metadata: {})
      validate_feedback_params!(suggestion_type, rating, prompt, response)

      payload = build_feedback_payload(
        suggestion_type: suggestion_type,
        prompt: prompt,
        response: response,
        rating: rating,
        feedback: feedback,
        metadata: metadata
      )

      api_response = self.class.post(
        api_url('/database/rlhf'),
        headers: headers,
        body: payload.to_json
      )

      handle_response_errors(api_response)
      parse_response(api_response)
    rescue StandardError => e
      Rails.logger.error("RLHF feedback logging failed: #{e.message}")
      raise
    end

    # Get RLHF statistics for account
    # Returns aggregate feedback metrics including counts and average ratings
    # @return [Hash] Statistics including total_feedback, avg_rating, feedback_by_type
    # @raise [StandardError] If API request fails
    def get_stats
      api_response = self.class.get(
        api_url('/database/rlhf/stats'),
        headers: headers,
        query: { account_id: @account_id }
      )

      handle_response_errors(api_response)
      parse_response(api_response)
    rescue StandardError => e
      Rails.logger.error("RLHF stats retrieval failed: #{e.message}")
      raise
    end

    # Convert thumbs up/down to rating scale
    # @param thumbs [Symbol] :up or :down
    # @return [Integer] 5 for thumbs up, 1 for thumbs down
    def self.thumbs_to_rating(thumbs)
      case thumbs
      when :up, 'up', 'thumbs_up'
        MAX_RATING
      when :down, 'down', 'thumbs_down'
        MIN_RATING
      else
        raise ArgumentError, "Invalid thumbs value: #{thumbs}. Use :up or :down"
      end
    end

    private

    # Validate feedback parameters
    # @raise [ArgumentError] If any validation fails
    def validate_feedback_params!(suggestion_type, rating, prompt, response)
      unless VALID_SUGGESTION_TYPES.include?(suggestion_type)
        raise ArgumentError, "Invalid suggestion_type: #{suggestion_type}. " \
                             "Must be one of: #{VALID_SUGGESTION_TYPES.join(', ')}"
      end

      unless rating.is_a?(Integer) && rating.between?(MIN_RATING, MAX_RATING)
        raise ArgumentError, "Invalid rating: #{rating}. Must be integer between #{MIN_RATING} and #{MAX_RATING}"
      end

      raise ArgumentError, 'Prompt cannot be blank' if prompt.blank?
      raise ArgumentError, 'Response cannot be blank' if response.blank?
    end

    # Build feedback payload for API request
    # @return [Hash] Payload for RLHF API endpoint
    def build_feedback_payload(suggestion_type:, prompt:, response:, rating:, feedback:, metadata:)
      {
        interaction_type: suggestion_type,
        prompt: prompt.to_s.strip,
        response: response.to_s.strip,
        rating: rating,
        feedback: feedback&.strip,
        metadata: metadata.merge(
          account_id: @account_id,
          timestamp: Time.current.iso8601
        )
      }
    end

    # Parse API response
    # @param response [HTTParty::Response] API response
    # @return [Hash] Parsed response body
    def parse_response(response)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse RLHF API response: #{e.message}")
      { success: response.success?, raw_body: response.body }
    end
  end
end
