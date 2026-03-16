import { inMemoryEventStore } from './inMemoryEventStore.js';
import type { AnalyticsEventPayload } from '../validators/event.validator.js';

export class EventStoreRepository {
  async saveRawEvent(event: AnalyticsEventPayload) {
    return inMemoryEventStore.add(event);
  }

  async listRawEvents() {
    return inMemoryEventStore.list();
  }
}
