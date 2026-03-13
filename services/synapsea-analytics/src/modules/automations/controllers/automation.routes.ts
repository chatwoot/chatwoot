import type { FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { AutomationService } from '../services/automation.service.js';
import {
  automationPayloadSchema,
  executeAutomationSchema,
  toggleAutomationSchema,
} from '../validators/automation.validator.js';

const automationService = new AutomationService();

export const registerAutomationRoutes = (app: FastifyInstance) => {
  app.get('/api/automations', async () => automationService.listAutomations());
  app.get('/api/automations/logs', async () => automationService.listLogs());

  app.post('/api/automations', async (request, reply) => {
    try {
      const payload = automationPayloadSchema.parse(request.body);
      const automation = automationService.createAutomation(payload);
      return reply.code(201).send(automation);
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.post('/api/automations/test', async (request, reply) => {
    try {
      const { event } = executeAutomationSchema.parse(request.body);
      return automationService.testAutomation(event);
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.post('/api/automations/validate-conflicts', async () => ({
    conflicts: automationService.validateConflicts(),
  }));

  app.post('/api/automations/suggest', async () => ({
    suggestions: automationService.suggestAutomations(),
  }));

  app.post('/api/automations/simulate', async (request, reply) => {
    try {
      const { event } = executeAutomationSchema.parse(request.body);
      return {
        simulation: true,
        expectedExecutions: automationService.executeByEvent(event),
      };
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.get('/api/automations/:id', async (request, reply) => {
    const { id } = request.params as { id: string };
    const automation = automationService.getAutomation(id);
    if (!automation) return reply.code(404).send({ error: 'Automation not found' });
    return automation;
  });

  app.put('/api/automations/:id', async (request, reply) => {
    try {
      const payload = automationPayloadSchema.parse(request.body);
      const { id } = request.params as { id: string };
      const automation = automationService.updateAutomation(id, payload);
      if (!automation) return reply.code(404).send({ error: 'Automation not found' });
      return automation;
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.delete('/api/automations/:id', async (request, reply) => {
    const { id } = request.params as { id: string };
    automationService.deleteAutomation(id);
    return reply.code(204).send();
  });

  app.patch('/api/automations/:id/toggle', async (request, reply) => {
    try {
      const { id } = request.params as { id: string };
      const { isActive } = toggleAutomationSchema.parse(request.body);
      const automation = automationService.toggleAutomation(id, isActive);
      if (!automation) return reply.code(404).send({ error: 'Automation not found' });
      return automation;
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.post('/api/automations/:id/duplicate', async (request, reply) => {
    const { id } = request.params as { id: string };
    const duplicated = automationService.duplicateAutomation(id);
    if (!duplicated) return reply.code(404).send({ error: 'Automation not found' });
    return reply.code(201).send(duplicated);
  });

  app.post('/api/automations/:id/execute', async (request, reply) => {
    try {
      const { id } = request.params as { id: string };
      const { event } = executeAutomationSchema.parse(request.body);
      const automation = automationService.getAutomation(id);
      if (!automation) return reply.code(404).send({ error: 'Automation not found' });

      return automationService.executeByEvent({
        ...event,
        type: automation.triggerType,
      });
    } catch (error) {
      if (error instanceof ZodError) {
        return reply.code(422).send({ error: error.flatten() });
      }
      throw error;
    }
  });

  app.get('/api/automations/:id/logs', async (request, reply) => {
    const { id } = request.params as { id: string };
    const automation = automationService.getAutomation(id);
    if (!automation) return reply.code(404).send({ error: 'Automation not found' });
    return automationService.listLogs(id);
  });
};
