# frozen_string_literal: true

require 'active_support/testing/time_helpers'

class Seeders::Reports::CsatResponseCreator
  include ActiveSupport::Testing::TimeHelpers

  # 70% of responses land at the extremes, with a slight lean toward 5.
  RATING_DISTRIBUTION = [1, 1, 1, 2, 3, 4, 5, 5, 5, 5].freeze

  def initialize(conversation:, resolved_at:)
    @conversation = conversation
    @resolved_at = resolved_at
  end

  def perform!
    responded_at = [@resolved_at + rand((1.minute)..(30.minutes)), Time.current].min

    travel_to(responded_at) do
      message = MessageTemplates::Template::CsatSurvey.new(conversation: @conversation).perform

      CsatSurveyResponse.create!(
        account: @conversation.account,
        conversation: @conversation,
        contact: @conversation.contact,
        message: message,
        assigned_agent: @conversation.assignee,
        rating: RATING_DISTRIBUTION.sample
      )
    end
  end
end
