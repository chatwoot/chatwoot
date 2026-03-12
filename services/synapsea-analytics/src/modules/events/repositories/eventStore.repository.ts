import type { AnalyticsEventPayload } from '../validators/event.validator.js';

export class EventStoreRepository {
  async saveRawEvent(event: AnalyticsEventPayload) {
    return {
      id: crypto.randomUUID(),
      processingStatus: 'pending',
      receivedAt: new Date().toISOString(),
      ...event,
    };
  }
}
