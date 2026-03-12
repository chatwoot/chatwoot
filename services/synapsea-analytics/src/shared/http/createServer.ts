import Fastify from 'fastify';
import { registerHealthRoutes } from '../../modules/health/controllers/health.routes.js';
import { registerEventRoutes } from '../../modules/events/controllers/event.routes.js';
import { registerReportRoutes } from '../../modules/reports/controllers/report.routes.js';
import { registerAiReportRoutes } from '../../modules/ai-reports/controllers/aiReport.routes.js';

export const createServer = () => {
  const app = Fastify({ logger: true });

  registerHealthRoutes(app);
  registerEventRoutes(app);
  registerReportRoutes(app);
  registerAiReportRoutes(app);

  return app;
};
