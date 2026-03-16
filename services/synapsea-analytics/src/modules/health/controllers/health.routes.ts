import type { FastifyInstance } from 'fastify';

export const registerHealthRoutes = (app: FastifyInstance) => {
  app.get('/health', async () => ({ status: 'ok' }));
};
