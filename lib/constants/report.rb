# frozen_string_literal: true

module Constants::Report
  ACCOUNT_METRICS = [:conversations_count,
                     :incoming_messages_count,
                     :outgoing_messages_count,
                     :avg_first_response_time,
                     :avg_resolution_time,
                     :resolutions_count].freeze

  AVG_ACCOUNT_METRICS = [:avg_first_response_time, :avg_resolution_time].freeze

  AGENT_METRICS = [:avg_first_response_time,
                   :avg_resolution_time,
                   :resolutions_count].freeze

  AVG_AGENT_METRICS = [:avg_first_response_time, :avg_resolution_time].freeze
end
