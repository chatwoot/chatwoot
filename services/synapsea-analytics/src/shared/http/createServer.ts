import Fastify from 'fastify';
import { registerHealthRoutes } from '../../modules/health/controllers/health.routes.js';
import { registerEventRoutes } from '../../modules/events/controllers/event.routes.js';
import { registerReportRoutes } from '../../modules/reports/controllers/report.routes.js';
import { registerAiReportRoutes } from '../../modules/ai-reports/controllers/aiReport.routes.js';
import { registerRoutingRoutes } from '../../modules/routing/controllers/routing.routes.js';
import { registerAutomationRoutes } from '../../modules/automations/controllers/automation.routes.js';
import { registerSupervisorRoutes } from '../../modules/supervisor/controllers/supervisor.routes.js';
import { registerSdrRoutes } from '../../modules/sdr/controllers/sdr.routes.js';
import { registerPlatformRoutes } from '../../modules/platform/controllers/platform.routes.js';

export const createServer = () => {
  const app = Fastify({ logger: true });

  registerHealthRoutes(app);
  registerEventRoutes(app);
  registerReportRoutes(app);
  registerAiReportRoutes(app);
  registerRoutingRoutes(app);
  registerAutomationRoutes(app);
  registerSupervisorRoutes(app);
  registerSdrRoutes(app);
  registerPlatformRoutes(app);

  return app;
};
