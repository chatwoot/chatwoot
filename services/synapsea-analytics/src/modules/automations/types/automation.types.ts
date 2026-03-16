export type TriggerType =
  | 'message.received'
  | 'conversation.created'
  | 'conversation.sla_risk'
  | 'ai.fallback_detected';

export type ConditionOperator =
  | 'equals'
  | 'not_equals'
  | 'contains'
  | 'not_contains'
  | 'greater_than'
  | 'less_than';

export type ActionType =
  | 'add_tag'
  | 'remove_tag'
  | 'transfer_to_queue'
  | 'assign_agent'
  | 'send_message'
  | 'create_internal_note'
  | 'escalate_ticket';

export type AutomationCondition = {
  id: string;
  field: string;
  operator: ConditionOperator;
  value: string | number | boolean;
  logicalGroup: 'and' | 'or';
};

export type AutomationAction = {
  id: string;
  type: ActionType;
  params: Record<string, string | number | boolean>;
  actionOrder: number;
};

export type Automation = {
  id: string;
  name: string;
  description?: string;
  triggerType: TriggerType;
  isActive: boolean;
  priority: number;
  stopOnMatch: boolean;
  cooldownSeconds: number;
  conditions: AutomationCondition[];
  actions: AutomationAction[];
  createdAt: string;
  updatedAt: string;
};

export type AutomationEvent = {
  type: TriggerType;
  ticketId?: string;
  context: Record<string, unknown>;
};

export type AutomationExecutionLog = {
  id: string;
  automationId: string;
  ticketId?: string;
  triggerEvent: TriggerType;
  executionStatus: 'success' | 'skipped' | 'failed';
  matched: boolean;
  evaluatedConditions: AutomationCondition[];
  executedActions: Array<{
    type: ActionType;
    status: 'executed' | 'skipped';
  }>;
  durationMs: number;
  errorMessage?: string;
  createdAt: string;
};
