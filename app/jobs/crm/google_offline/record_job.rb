class Crm::GoogleOffline::RecordJob < ApplicationJob
  queue_as :low

  DEFAULT_CONVERSION_NAMES = {
    'won' => 'Venda WhatsApp',
    'lost' => 'Lead Perdido WhatsApp'
  }.freeze

  def perform(account_id, card_id, activity_id, event_type)
    card = Crm::Card.find_by(id: card_id, account_id: account_id)
    return if card.blank?

    activity = Crm::Activity.find_by(id: activity_id, account_id: account_id, card_id: card_id)
    stage = event_stage(card, event_type, activity)
    attribution = Crm::GoogleOffline::GclidResolver.resolve_with_conversation(card)
    context = { activity: activity, stage: stage, attribution: attribution, activity_id: activity_id, event_type: event_type }

    Crm::GoogleConversionEvent.create!(event_attributes(card, context))
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  private

  def event_attributes(card, context)
    activity = context[:activity]
    stage = context[:stage]
    attribution = context[:attribution]
    activity_id = context[:activity_id]
    event_type = context[:event_type]

    {
      account_id: card.account_id,
      card_id: card.id,
      conversation_id: attribution&.conversation_id,
      activity_id: activity_id,
      event_id: "crm-#{card.id}-#{event_type}-#{activity_id}",
      gclid: attribution&.gclid,
      conversion_name: conversion_name(card, stage, event_type),
      conversion_time: conversion_time(card, activity, event_type),
      status: attribution.present? ? 'ready' : 'skipped',
      skip_reason: attribution.present? ? nil : 'missing_gclid'
    }.merge(value_attributes(card, event_type))
  end

  # won/lost resolve by event type (what the UI configures); moved resolves by the
  # destination stage's funnel type.
  def conversion_name(card, stage, event_type)
    configured_conversion_name(card, stage, event_type).presence || default_conversion_name(stage, event_type)
  end

  def configured_conversion_name(card, stage, event_type)
    names = card.pipeline.metadata.dig('google_sync', 'conversion_names') || {}
    return names[event_type] if %w[won lost].include?(event_type)

    stage_type = stage&.metadata&.dig('funnel_stage_type').presence
    names[stage_type] if stage_type
  end

  def default_conversion_name(stage, event_type)
    return stage.name if event_type == 'moved' && stage.present?

    DEFAULT_CONVERSION_NAMES.fetch(event_type, event_type.humanize)
  end

  def conversion_time(card, activity, event_type)
    activity&.created_at || (card.closed_at if %w[won lost].include?(event_type)) || card.entered_stage_at || Time.current
  end

  def value_attributes(card, event_type)
    return {} unless event_type == 'won'

    { value_cents: card.value_cents, currency: card.currency }
  end

  def event_stage(card, event_type, activity)
    return card.stage unless event_type == 'moved'

    to_stage_id = activity&.payload&.dig('to_stage_id')
    Crm::PipelineStage.find_by(id: to_stage_id, account_id: card.account_id) || card.stage
  end
end
