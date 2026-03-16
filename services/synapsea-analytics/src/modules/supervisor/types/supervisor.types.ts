export type SupervisorOverview = {
  conversationsActive: number;
  queueSize: number;
  newConversationsToday: number;
  resolvedToday: number;
  slaAtRisk: number;
  slaBreached: number;
  avgFirstResponseSeconds: number;
  avgResolutionSeconds: number;
  agentsOnline: number;
  capacityTotal: number;
  currentLoad: number;
  overloadedAgents: number;
  idleAgents: number;
};

export type QueueStatus = {
  queueId: string;
  queueName: string;
  department: string;
  volume: number;
  slaRisk: number;
  averageWaitSeconds: number;
  health: 'healthy' | 'attention' | 'critical';
};

export type SupervisorAlert = {
  id: string;
  severity: 'warning' | 'critical';
  type: 'sla_risk' | 'queue_overflow' | 'agent_overload' | 'ai_fallback' | 'automation_failure';
  title: string;
  description: string;
  createdAt: string;
};
