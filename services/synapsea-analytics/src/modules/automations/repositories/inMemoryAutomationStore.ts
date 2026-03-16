import type {
  Automation,
  AutomationExecutionLog,
} from '../types/automation.types.js';

class InMemoryAutomationStore {
  private automations: Automation[] = [
    {
      id: 'automation-finance-triage',
      name: 'Encaminhar cobrança para financeiro',
      description: 'Tag de cobrança + transferência para fila financeira',
      triggerType: 'message.received',
      isActive: true,
      priority: 10,
      stopOnMatch: true,
      cooldownSeconds: 120,
      conditions: [
        {
          id: 'cond-boleto',
          field: 'message.content',
          operator: 'contains',
          value: 'boleto',
          logicalGroup: 'and',
        },
      ],
      actions: [
        {
          id: 'action-tag',
          type: 'add_tag',
          params: { tag: 'cobranca' },
          actionOrder: 1,
        },
        {
          id: 'action-transfer',
          type: 'transfer_to_queue',
          params: { queueId: 'q-finance' },
          actionOrder: 2,
        },
        {
          id: 'action-reply',
          type: 'send_message',
          params: {
            template:
              'Recebemos sua solicitação e já encaminhamos ao time financeiro.',
          },
          actionOrder: 3,
        },
      ],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
  ];

  private logs: AutomationExecutionLog[] = [];

  private cooldownMap = new Map<string, string>();

  listAutomations() {
    return this.automations;
  }

  getAutomation(id: string) {
    return this.automations.find(automation => automation.id === id);
  }

  saveAutomation(automation: Automation) {
    const existingIndex = this.automations.findIndex(item => item.id === automation.id);
    if (existingIndex >= 0) {
      this.automations[existingIndex] = automation;
      return automation;
    }

    this.automations.push(automation);
    return automation;
  }

  deleteAutomation(id: string) {
    this.automations = this.automations.filter(automation => automation.id !== id);
  }

  listLogs(automationId?: string) {
    if (!automationId) return this.logs;
    return this.logs.filter(log => log.automationId === automationId);
  }

  addLog(log: AutomationExecutionLog) {
    this.logs.unshift(log);
    return log;
  }

  getCooldown(automationId: string, entityId: string) {
    return this.cooldownMap.get(`${automationId}:${entityId}`);
  }

  setCooldown(automationId: string, entityId: string, executedAt: string) {
    this.cooldownMap.set(`${automationId}:${entityId}`, executedAt);
  }
}

export const inMemoryAutomationStore = new InMemoryAutomationStore();
