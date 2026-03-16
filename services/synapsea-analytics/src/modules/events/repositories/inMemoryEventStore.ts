import type { AnalyticsEventPayload } from '../validators/event.validator.js';

type StoredEvent = AnalyticsEventPayload & {
  id: string;
  receivedAt: string;
  processingStatus: 'pending' | 'processed' | 'failed';
};

const events: StoredEvent[] = [];

export const inMemoryEventStore = {
  add(event: AnalyticsEventPayload) {
    const stored: StoredEvent = {
      ...event,
      id: crypto.randomUUID(),
      receivedAt: new Date().toISOString(),
      processingStatus: 'pending',
    };

    events.push(stored);
    return stored;
  },

  list() {
    return [...events];
  },
};
