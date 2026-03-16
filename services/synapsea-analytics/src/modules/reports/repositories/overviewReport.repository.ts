 codex/transform-chatwoot-into-synapsea-connect-ymy4px

 codex/transform-chatwoot-into-synapsea-connect-nhivec
 develop
import { EventStoreRepository } from '../../events/repositories/eventStore.repository.js';
import type { OverviewFilters, OverviewReport } from '../types/report.types.js';

const toTimestamp = (value: string) => new Date(value).getTime();

export class OverviewReportRepository {
  constructor(private readonly eventStore = new EventStoreRepository()) {}

  async getOverview(filters: OverviewFilters): Promise<OverviewReport> {
    const events = await this.eventStore.listRawEvents();
    const start = toTimestamp(filters.dateFrom);
    const end = toTimestamp(filters.dateTo);

    const filtered = events.filter(event => {
      const occurredAt = toTimestamp(event.occurredAt);
      return occurredAt >= start && occurredAt <= end;
    });

    const conversationCreated = filtered.filter(
      event => event.eventType === 'conversation.created'
    );

    const conversationIds = new Set(
      conversationCreated.map(event =>
        String(event.payload.conversationId || event.externalId || event.id)
      )
    );

    const totalConversations = conversationIds.size;

    const aiResolvedEvents = filtered.filter(
      event => event.eventType === 'ai.resolved_without_human'
    ).length;

    const firstResponseBreaches = filtered.filter(
      event => event.eventType === 'sla.first_response_breached'
    ).length;

    const resolutionBreaches = filtered.filter(
      event => event.eventType === 'sla.resolution_breached'
    ).length;

    const slaFirstResponseRate =
      totalConversations > 0
        ? Number(
            (((totalConversations - firstResponseBreaches) / totalConversations) *
              100).toFixed(2)
          )
        : 0;

    const slaResolutionRate =
      totalConversations > 0
        ? Number(
            (((totalConversations - resolutionBreaches) / totalConversations) *
              100).toFixed(2)
          )
        : 0;

    const aiResolutionRate =
      totalConversations > 0
        ? Number(((aiResolvedEvents / totalConversations) * 100).toFixed(2))
        : 0;

    return {
      totalConversations,
      avgFirstResponseSeconds: 0,
      avgResolutionSeconds: 0,
      slaFirstResponseRate,
      slaResolutionRate,
      aiResolutionRate,
 codex/transform-chatwoot-into-synapsea-connect-ymy4px


import type { OverviewFilters, OverviewReport } from '../types/report.types.js';

export class OverviewReportRepository {
  async getOverview(_filters: OverviewFilters): Promise<OverviewReport> {
    return {
      totalConversations: 0,
      avgFirstResponseSeconds: 0,
      avgResolutionSeconds: 0,
      slaFirstResponseRate: 0,
      slaResolutionRate: 0,
      aiResolutionRate: 0,
 develop
 develop
    };
  }
}
