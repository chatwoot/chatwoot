import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { GetOverviewReportService } from '../services/getOverviewReport.service.js';

const querySchema = z.object({
  dateFrom: z.string().datetime(),
  dateTo: z.string().datetime(),
  inboxIds: z.string().optional(),
});

export const registerReportRoutes = (app: FastifyInstance) => {
  const service = new GetOverviewReportService();

  app.get('/api/reports/overview', async request => {
    const query = querySchema.parse(request.query);

    const result = await service.execute({
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      inboxIds: query.inboxIds?.split(',').filter(Boolean),
    });

    return result;
  });
};
