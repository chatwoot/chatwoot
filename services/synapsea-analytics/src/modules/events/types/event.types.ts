export type SupportedEventType =
  | 'conversation.created'
  | 'conversation.assigned'
  | 'conversation.resolved'
  | 'message.received'
  | 'message.sent'
  | 'ai.answer_generated'
  | 'ai.handoff_to_human'
 codex/transform-chatwoot-into-synapsea-connect-nhivec
  | 'ai.resolved_without_human'
  | 'lead.qualified'
  | 'sla.first_response_breached'
  | 'sla.resolution_breached';

  | 'lead.qualified'
  | 'sla.first_response_breached';
 develop

export type AnalyticsEvent = {
  eventType: SupportedEventType;
  source: 'chatwoot' | 'connect' | 'ai-service';
  externalId?: string;
  occurredAt: string;
  payload: Record<string, unknown>;
};
