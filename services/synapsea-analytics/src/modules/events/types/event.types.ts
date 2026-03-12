export type SupportedEventType =
  | 'conversation.created'
  | 'conversation.assigned'
  | 'conversation.resolved'
  | 'message.received'
  | 'message.sent'
  | 'ai.answer_generated'
  | 'ai.handoff_to_human'
  | 'lead.qualified'
  | 'sla.first_response_breached';

export type AnalyticsEvent = {
  eventType: SupportedEventType;
  source: 'chatwoot' | 'connect' | 'ai-service';
  externalId?: string;
  occurredAt: string;
  payload: Record<string, unknown>;
};
