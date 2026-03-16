import type { FastifyInstance } from 'fastify';
import { askAiSchema } from '../validators/askAi.validator.js';
import { GenerateAnswerService } from '../services/generateAnswer.service.js';

export const registerAiReportRoutes = (app: FastifyInstance) => {
  const service = new GenerateAnswerService();

  app.post('/api/reports/ask-ai', async request => {
    const payload = askAiSchema.parse(request.body);
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
    return await service.execute(payload);

 codex/transform-chatwoot-into-synapsea-connect-vkjace
    return await service.execute(payload);

 codex/transform-chatwoot-into-synapsea-connect-ymy4px
    return await service.execute(payload);

 codex/transform-chatwoot-into-synapsea-connect-nhivec
    return await service.execute(payload);

    return service.execute(payload);
 develop
 develop
 develop
 develop
  });
};
