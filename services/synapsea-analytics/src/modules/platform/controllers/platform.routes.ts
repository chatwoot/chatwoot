import type { FastifyInstance } from 'fastify';
import { PlatformService } from '../services/platform.service.js';

const platformService = new PlatformService();

export const registerPlatformRoutes = (app: FastifyInstance) => {
  app.get('/api/platform/blueprint', async () => platformService.getBlueprint());
  app.get('/api/platform/events', async () => platformService.listCanonicalEvents());
};
