import { inMemoryAutomationStore } from '../repositories/inMemoryAutomationStore.js';
import type {
  Automation,
  AutomationAction,
  AutomationCondition,
  AutomationEvent,
  AutomationExecutionLog,
} from '../types/automation.types.js';

type AutomationConditionInput = Omit<AutomationCondition, 'id'> & { id?: string };
type AutomationActionInput = Omit<AutomationAction, 'id'> & { id?: string };
type AutomationPayload = Omit<Automation, 'id' | 'isActive' | 'createdAt' | 'updatedAt' | 'conditions' | 'actions'> & {
  isActive?: boolean;
  conditions: AutomationConditionInput[];
  actions: AutomationActionInput[];
};

const resolveFieldValue = (source: Record<string, unknown>, path: string): unknown => {
  return path
    .split('.')
    .reduce<unknown>((acc, key) => (acc && typeof acc === 'object' ? (acc as Record<string, unknown>)[key] : undefined), source);
};

const evaluateCondition = (condition: AutomationCondition, context: Record<string, unknown>) => {
  const actualValue = resolveFieldValue(context, condition.field);
  const normalizedActual = String(actualValue ?? '').toLowerCase();
  const normalizedExpected = String(condition.value).toLowerCase();

  switch (condition.operator) {
    case 'equals':
      return normalizedActual === normalizedExpected;
    case 'not_equals':
      return normalizedActual !== normalizedExpected;
    case 'contains':
      return normalizedActual.includes(normalizedExpected);
    case 'not_contains':
      return !normalizedActual.includes(normalizedExpected);
    case 'greater_than':
      return Number(actualValue ?? 0) > Number(condition.value);
    case 'less_than':
      return Number(actualValue ?? 0) < Number(condition.value);
    default:
      return false;
  }
};

const evaluateConditions = (
  conditions: AutomationCondition[],
  context: Record<string, unknown>
) => {
  const andConditions = conditions.filter(condition => condition.logicalGroup === 'and');
  const orConditions = conditions.filter(condition => condition.logicalGroup === 'or');

  const andPass = andConditions.every(condition => evaluateCondition(condition, context));
  const orPass = orConditions.length === 0 || orConditions.some(condition => evaluateCondition(condition, context));

  return andPass && orPass;
};

const executeAction = (action: AutomationAction) => {
  return {
    type: action.type,
    status: 'executed' as const,
  };
};

export class AutomationService {
  listAutomations() {
    return inMemoryAutomationStore
      .listAutomations()
      .sort((a, b) => a.priority - b.priority);
  }

  getAutomation(id: string) {
    return inMemoryAutomationStore.getAutomation(id);
  }

  createAutomation(payload: AutomationPayload) {
    const now = new Date().toISOString();
    const automation: Automation = {
      ...payload,
      id: crypto.randomUUID(),
      isActive: payload.isActive ?? true,
      conditions: payload.conditions.map(condition => ({
        ...condition,
        id: crypto.randomUUID(),
      })),
      actions: payload.actions.map(action => ({
        ...action,
        id: crypto.randomUUID(),
      })),
      createdAt: now,
      updatedAt: now,
    };

    return inMemoryAutomationStore.saveAutomation(automation);
  }

  updateAutomation(id: string, payload: AutomationPayload) {
    const current = inMemoryAutomationStore.getAutomation(id);
    if (!current) return undefined;

    return inMemoryAutomationStore.saveAutomation({
      ...current,
      ...payload,
      conditions: payload.conditions.map(condition => ({
        ...condition,
        id: condition.id || crypto.randomUUID(),
      })),
      actions: payload.actions.map(action => ({
        ...action,
        id: action.id || crypto.randomUUID(),
      })),
      updatedAt: new Date().toISOString(),
    });
  }

  toggleAutomation(id: string, isActive: boolean) {
    const current = inMemoryAutomationStore.getAutomation(id);
    if (!current) return undefined;

    return inMemoryAutomationStore.saveAutomation({
      ...current,
      isActive,
      updatedAt: new Date().toISOString(),
    });
  }

  duplicateAutomation(id: string) {
    const current = inMemoryAutomationStore.getAutomation(id);
    if (!current) return undefined;

    return this.createAutomation({
      ...current,
      name: `${current.name} (copy)`,
      conditions: current.conditions,
      actions: current.actions,
    });
  }

  deleteAutomation(id: string) {
    inMemoryAutomationStore.deleteAutomation(id);
  }

  executeByEvent(event: AutomationEvent) {
    const start = Date.now();
    const results: AutomationExecutionLog[] = [];

    const automations = this.listAutomations().filter(
      automation => automation.isActive && automation.triggerType === event.type
    );

    for (const automation of automations) {
      const matched = evaluateConditions(automation.conditions, event.context);

      if (!matched) {
        results.push(
          inMemoryAutomationStore.addLog({
            id: crypto.randomUUID(),
            automationId: automation.id,
            ticketId: event.ticketId,
            triggerEvent: event.type,
            executionStatus: 'skipped',
            matched: false,
            evaluatedConditions: automation.conditions,
            executedActions: [],
            durationMs: Date.now() - start,
            createdAt: new Date().toISOString(),
          })
        );
        continue;
      }

      if (event.ticketId && automation.cooldownSeconds > 0) {
        const cooldownAt = inMemoryAutomationStore.getCooldown(
          automation.id,
          event.ticketId
        );

        if (cooldownAt) {
          const elapsedSeconds =
            (Date.now() - new Date(cooldownAt).getTime()) / 1000;
          if (elapsedSeconds < automation.cooldownSeconds) {
            results.push(
              inMemoryAutomationStore.addLog({
                id: crypto.randomUUID(),
                automationId: automation.id,
                ticketId: event.ticketId,
                triggerEvent: event.type,
                executionStatus: 'skipped',
                matched: true,
                evaluatedConditions: automation.conditions,
                executedActions: [],
                durationMs: Date.now() - start,
                errorMessage: 'Skipped by cooldown protection',
                createdAt: new Date().toISOString(),
              })
            );
            continue;
          }
        }
      }

      const orderedActions = [...automation.actions].sort(
        (a, b) => a.actionOrder - b.actionOrder
      );

      const executedActions = orderedActions.map(action => executeAction(action));

      results.push(
        inMemoryAutomationStore.addLog({
          id: crypto.randomUUID(),
          automationId: automation.id,
          ticketId: event.ticketId,
          triggerEvent: event.type,
          executionStatus: 'success',
          matched: true,
          evaluatedConditions: automation.conditions,
          executedActions,
          durationMs: Date.now() - start,
          createdAt: new Date().toISOString(),
        })
      );

      if (event.ticketId && automation.cooldownSeconds > 0) {
        inMemoryAutomationStore.setCooldown(
          automation.id,
          event.ticketId,
          new Date().toISOString()
        );
      }

      if (automation.stopOnMatch) break;
    }

    return results;
  }

  testAutomation(event: AutomationEvent) {
    return this.executeByEvent(event);
  }

  listLogs(automationId?: string) {
    return inMemoryAutomationStore.listLogs(automationId);
  }

  validateConflicts() {
    const automations = this.listAutomations();
    const conflicts = automations.flatMap(automation => {
      const sameTrigger = automations.filter(
        candidate =>
          candidate.id !== automation.id &&
          candidate.triggerType === automation.triggerType &&
          candidate.priority === automation.priority
      );

      return sameTrigger.map(candidate => ({
        automationId: automation.id,
        conflictsWith: candidate.id,
        reason: 'Same trigger and priority can cause conflicting execution order',
      }));
    });

    return conflicts;
  }

  suggestAutomations() {
    return [
      {
        name: 'Escalar SLA em risco automaticamente',
        triggerType: 'conversation.sla_risk',
        recommendation:
          'Quando uma conversa estiver em risco de SLA, escalar prioridade e notificar supervisor.',
      },
      {
        name: 'Fallback de IA para humano',
        triggerType: 'ai.fallback_detected',
        recommendation:
          'Após fallback da IA, criar nota interna com resumo e transferir para fila especializada.',
      },
    ];
  }
}
