import type { FastifyInstance } from 'fastify';
import { analyticsEventSchema } from '../validators/event.validator.js';
import { IngestEventService } from '../services/ingestEvent.service.js';

export const registerEventRoutes = (app: FastifyInstance) => {
  const service = new IngestEventService();

  app.post('/api/events', async request => {
    const payload = analyticsEventSchema.parse(request.body);
    const result = await service.execute(payload);

    return {
      message: 'Event accepted',
      eventId: result.id,
      processingStatus: result.processingStatus,
    };
  });
};
