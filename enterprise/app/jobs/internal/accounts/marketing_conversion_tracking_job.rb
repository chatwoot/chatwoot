# frozen_string_literal: true

class Internal::Accounts::MarketingConversionTrackingJob < ApplicationJob
  queue_as :low

  def perform(account_id, event_name, occurred_at = nil, conversion_value = nil, currency_code = nil)
    account = Account.find_by(id: account_id)
    return if account.blank?

    Internal::Accounts::MarketingConversionTrackingService.new(
      account: account,
      event_name: event_name,
      occurred_at: occurred_at,
      conversion_value: conversion_value,
      currency_code: currency_code
    ).perform
  end
end
