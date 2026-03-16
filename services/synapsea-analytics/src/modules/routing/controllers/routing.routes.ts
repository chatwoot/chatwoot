import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { RoutingService } from '../services/routing.service.js';
import {
  assignTicketSchema,
  createTicketSchema,
  enqueueTicketSchema,
  escalateTicketSchema,
  transferTicketSchema,
} from '../validators/routing.validator.js';

const paramsSchema = z.object({ id: z.string().min(1) });

export const registerRoutingRoutes = (app: FastifyInstance) => {
  const service = new RoutingService();

  app.post('/api/tickets', async request => {
    const payload = createTicketSchema.parse(request.body);
    return service.createTicket(payload);
  });

  app.post('/api/tickets/:id/transfer', async request => {
    const { id } = paramsSchema.parse(request.params);
    const payload = transferTicketSchema.parse(request.body);
    return service.transferTicket(id, payload);
  });

  app.post('/api/tickets/:id/assign', async request => {
    const { id } = paramsSchema.parse(request.params);
    const payload = assignTicketSchema.parse(request.body);
    return service.assignTicket(id, payload.assigneeId);
  });

  app.post('/api/tickets/:id/enqueue', async request => {
    const { id } = paramsSchema.parse(request.params);
    const payload = enqueueTicketSchema.parse(request.body);
    return service.enqueueTicket(id, payload.queueId);
  });

  app.post('/api/tickets/:id/escalate', async request => {
    const { id } = paramsSchema.parse(request.params);
    const payload = escalateTicketSchema.parse(request.body);
    return service.escalateTicket(id, payload.reason);
  });

  app.get('/api/routing/queues/heatmap', async () => {
    return service.getQueueHeatmap();
  });

  app.get('/api/routing/workload', async () => {
    return service.getWorkloadByAgent();
  });
};
