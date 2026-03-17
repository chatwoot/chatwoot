import type { FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { SupervisorService } from '../services/supervisor.service.js';
import { redistributeSchema } from '../validators/supervisor.validator.js';

const supervisorService = new SupervisorService();

export const registerSupervisorRoutes = (app: FastifyInstance) => {
  app.get('/api/supervisor/overview', async () => supervisorService.getOverview());
  app.get('/api/supervisor/queues', async () => supervisorService.getQueues());
  app.get('/api/supervisor/agents', async () => supervisorService.getAgents());
  app.get('/api/supervisor/alerts', async () => supervisorService.getAlerts());
  app.get('/api/supervisor/ai', async () => supervisorService.getAiMetrics());
  app.get('/api/supervisor/automations', async () =>
    supervisorService.getAutomationMetrics()
  );

  app.post('/api/supervisor/redistribute', async (request, reply) => {
    try {
      const payload = redistributeSchema.parse(request.body);
      return supervisorService.redistribute(payload);
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });
};
