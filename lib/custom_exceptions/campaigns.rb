# frozen_string_literal: true

module CustomExceptions::Campaigns
  # Raised when a campaign is dispatched to an inbox type that has no outbound
  # send path wired in Campaigns::ChannelStrategy.
  class UnsupportedInboxType < CustomExceptions::Base
    def initialize(inbox_type = nil)
      super
      @inbox_type = inbox_type
    end

    def message
      "Campaigns are not supported for inbox type: #{@inbox_type}"
    end
  end
end
