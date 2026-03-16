import type { FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { SDRService } from '../services/sdr.service.js';
import { leadImportSchema, sdrStartSchema } from '../validators/sdr.validator.js';

const sdrService = new SDRService();

export const registerSdrRoutes = (app: FastifyInstance) => {
  app.post('/api/leads/import', async (request, reply) => {
    try {
      const payload = leadImportSchema.parse(request.body);
      return reply.code(201).send(sdrService.importLeads(payload.leads));
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.post('/api/sdr/start', async (request, reply) => {
    try {
      const payload = sdrStartSchema.parse(request.body || {});
      const result = sdrService.startProspection(payload);

      if (!result) {
        return reply.code(404).send({ error: 'No lead available for SDR start' });
      }

      return result;
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.get('/api/sdr/metrics', async () => sdrService.getMetrics());
  app.get('/api/sdr/qualified', async () => sdrService.getQualifiedLeads());
};
