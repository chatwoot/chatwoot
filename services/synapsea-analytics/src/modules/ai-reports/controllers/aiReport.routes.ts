import type { FastifyInstance } from 'fastify';
import { askAiSchema } from '../validators/askAi.validator.js';
import { GenerateAnswerService } from '../services/generateAnswer.service.js';

export const registerAiReportRoutes = (app: FastifyInstance) => {
  const service = new GenerateAnswerService();

  app.post('/api/reports/ask-ai', async request => {
    const payload = askAiSchema.parse(request.body);
    return service.execute(payload);
  });
};
