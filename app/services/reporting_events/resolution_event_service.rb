class ReportingEvents::ResolutionEventService
  include ReportingEventHelper

  attr_reader :conversation

  def initialize(conversation)
    @conversation = conversation
  end

  def create_conversation_resolved_events(start_time, end_time, time_to_resolve)
    user_ids = conversation.conversation_participants.where.not(user_id: nil).distinct.pluck(:user_id)

    user_ids.each do |user_id|
      build_conversation_resolved_event(user_id, start_time, end_time, time_to_resolve)
    end

    bot_service.create_bot_resolved_event
  end

  def create_resolution_without_bot_events(opened_time)
    start_time = opened_time
    end_time = conversation.resolved_at
    resolution_time = end_time.to_i - start_time.to_i

    return if resolution_time <= 0

    user_ids = conversation.conversation_participants.where.not(user_id: nil).distinct.pluck(:user_id)

    user_ids.each do |user_id|
      build_resolution_without_bot_event(user_id, start_time, end_time, resolution_time)
    end
  end

  def create_conversation_opened_event(time_since_resolved, business_hours_value, start_time)
    reporting_event = ReportingEvent.new(
      name: 'conversation_opened',
      value: time_since_resolved,
      value_in_business_hours: business_hours_value,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: conversation.updated_at
    )
    reporting_event.save!
  end

  def find_last_opened_event
    ReportingEvent.where(
      conversation_id: conversation.id,
      name: 'conversation_opened'
    ).where('event_end_time <= ?', conversation.resolved_at)
                  .order(event_end_time: :desc)
                  .first
  end

  def find_last_resolved_event
    ReportingEvent.where(
      conversation_id: conversation.id,
      name: 'conversation_resolved'
    ).order(event_end_time: :desc).first
  end

  private

  def build_conversation_resolved_event(user_id, start_time, end_time, time_to_resolve)
    reporting_event = ReportingEvent.new(
      name: 'conversation_resolved',
      value: time_to_resolve,
      value_in_business_hours: business_hours(conversation.inbox, start_time, end_time),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: user_id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: end_time
    )
    reporting_event.save!
  end

  def build_resolution_without_bot_event(user_id, start_time, end_time, resolution_time)
    reporting_event = ReportingEvent.new(
      name: 'resolution_time_without_bot',
      value: resolution_time,
      value_in_business_hours: business_hours(conversation.inbox, start_time, end_time),
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: user_id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: end_time
    )
    reporting_event.save!
  end

  def bot_service
    @bot_service ||= ReportingEvents::BotEventService.new(conversation)
  end
end
