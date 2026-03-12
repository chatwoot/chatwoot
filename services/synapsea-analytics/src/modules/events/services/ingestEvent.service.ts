import type { AnalyticsEventPayload } from '../validators/event.validator.js';
import { EventStoreRepository } from '../repositories/eventStore.repository.js';

export class IngestEventService {
  constructor(private readonly eventStore = new EventStoreRepository()) {}

  async execute(event: AnalyticsEventPayload) {
    return this.eventStore.saveRawEvent(event);
  }
}
