# frozen_string_literal: true

# Provides Calendly scheduling support for conversation agents
module CalendlySupport
  extend ActiveSupport::Concern

  private

  def calendly_tools
    return [] unless calendly_access_enabled?

    [CalendlyShareLinkTool, CalendlyCheckAvailabilityTool, CalendlyListEventsTool]
  end

  def calendly_access_enabled?
    current_assistant&.feature_calendly_enabled? && calendly_connected?
  end

  def calendly_connected?
    current_account&.hooks&.exists?(app_id: 'calendly')
  end
end
