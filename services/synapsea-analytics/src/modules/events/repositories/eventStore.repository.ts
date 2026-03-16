 codex/transform-chatwoot-into-synapsea-connect-vkjace
import { inMemoryEventStore } from './inMemoryEventStore.js';

 codex/transform-chatwoot-into-synapsea-connect-ymy4px
import { inMemoryEventStore } from './inMemoryEventStore.js';

 codex/transform-chatwoot-into-synapsea-connect-nhivec
import { inMemoryEventStore } from './inMemoryEventStore.js';

 develop
 develop
 develop
import type { AnalyticsEventPayload } from '../validators/event.validator.js';

export class EventStoreRepository {
  async saveRawEvent(event: AnalyticsEventPayload) {
 codex/transform-chatwoot-into-synapsea-connect-vkjace

 codex/transform-chatwoot-into-synapsea-connect-ymy4px

 codex/transform-chatwoot-into-synapsea-connect-nhivec
 develop
 develop
    return inMemoryEventStore.add(event);
  }

  async listRawEvents() {
    return inMemoryEventStore.list();
 codex/transform-chatwoot-into-synapsea-connect-vkjace

 codex/transform-chatwoot-into-synapsea-connect-ymy4px


    return {
      id: crypto.randomUUID(),
      processingStatus: 'pending',
      receivedAt: new Date().toISOString(),
      ...event,
    };
 develop
 develop
 develop
  }
}
