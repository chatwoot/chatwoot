# frozen_string_literal: true

# Provides payment link history support for conversation agents
module PaymentLinkSupport
  extend ActiveSupport::Concern

  private

  def payment_link_instructions
    return nil unless payment_link_access_enabled?

    <<~PROMPT
      #{section_header('PAYMENT LINKS')}

      Rules:

      1. Use payment_link_history tool when the customer asks about their payment history or payment status
    PROMPT
  end

  def payment_link_tools
    return [] unless payment_link_access_enabled?

    [PaymentLinkHistoryTool]
  end

  def payment_link_access_enabled?
    current_account&.payment_link_settings.present?
  end
end
