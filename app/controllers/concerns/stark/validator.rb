module Stark
  module Validator
    extend ActiveSupport::Concern

    included do
      UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      VALID_EVENTS = %w[message.created].freeze
    end

    def can_process_message?
      valid_event_name? && valid_bot_url? && incoming_message? && unassigned_conversation?
    end

    def valid_event_name?
      VALID_EVENTS.include?(event_name)
    end

    def valid_bot_url?
      agent_bot.outgoing_url.present?
    end

    def incoming_message?
      event_data[:message].incoming?
    end

    def unassigned_conversation?
      event_data[:message].conversation.assignee_id.blank?
    end

    def valid_dealership_id?(dealership_id)
      dealership_id.present? && dealership_id.match?(UUID_REGEX)
    end
  end
end
