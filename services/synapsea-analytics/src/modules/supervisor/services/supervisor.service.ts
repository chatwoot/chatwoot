import { AutomationService } from '../../automations/services/automation.service.js';
import { inMemoryEventStore } from '../../events/repositories/inMemoryEventStore.js';
import { inMemoryRoutingStore } from '../../routing/repositories/inMemoryRoutingStore.js';
import type {
  QueueStatus,
  SupervisorAlert,
  SupervisorOverview,
} from '../types/supervisor.types.js';

const toHealth = (volume: number, maxCapacity: number): QueueStatus['health'] => {
  const ratio = maxCapacity > 0 ? volume / maxCapacity : 0;
  if (ratio >= 0.85) return 'critical';
  if (ratio >= 0.6) return 'attention';
  return 'healthy';
};

export class SupervisorService {
  private automationService = new AutomationService();

  getOverview(): SupervisorOverview {
    const tickets = inMemoryRoutingStore.listTickets();
    const events = inMemoryEventStore.list();
    const agents = inMemoryRoutingStore.listAgents();

    const queueSize = tickets.filter(ticket => !ticket.assigneeId).length;
    const conversationsActive = tickets.filter(ticket => ticket.status === 'open').length;
    const today = new Date().toISOString().slice(0, 10);

    const newConversationsToday = events.filter(
      event => event.eventType === 'conversation.created' && event.occurredAt.startsWith(today)
    ).length;

    const resolvedToday = events.filter(
      event => event.eventType === 'conversation.resolved' && event.occurredAt.startsWith(today)
    ).length;

    const slaAtRisk = tickets.filter(ticket => ticket.priority === 'high').length;
    const slaBreached = events.filter(event => event.eventType.includes('sla.')).length;

    const avgFirstResponseSeconds = 151;
    const avgResolutionSeconds = 940;

    const agentsOnline = agents.filter(agent => agent.status !== 'offline').length;
    const capacityTotal = agents.reduce((total, agent) => total + agent.maxCapacity, 0);
    const currentLoad = agents.reduce((total, agent) => total + agent.currentLoad, 0);
    const overloadedAgents = agents.filter(
      agent => agent.currentLoad >= agent.maxCapacity
    ).length;
    const idleAgents = agents.filter(agent => agent.currentLoad <= 1).length;

    return {
      conversationsActive,
      queueSize,
      newConversationsToday,
      resolvedToday,
      slaAtRisk,
      slaBreached,
      avgFirstResponseSeconds,
      avgResolutionSeconds,
      agentsOnline,
      capacityTotal,
      currentLoad,
      overloadedAgents,
      idleAgents,
    };
  }

  getQueues() {
    const tickets = inMemoryRoutingStore.listTickets();

    return inMemoryRoutingStore.listQueues().map(queue => {
      const queueTickets = tickets.filter(ticket => ticket.queueId === queue.id);
      const slaRisk = queueTickets.filter(ticket => ticket.priority === 'urgent').length;

      return {
        queueId: queue.id,
        queueName: queue.name,
        department: queue.department,
        volume: queueTickets.length,
        slaRisk,
        averageWaitSeconds: queueTickets.length * 45,
        health: toHealth(queueTickets.length, queue.maxCapacity),
      };
    });
  }

  getAgents() {
    const tickets = inMemoryRoutingStore.listTickets();

    return inMemoryRoutingStore.listAgents().map(agent => ({
      agentId: agent.id,
      name: agent.name,
      status: agent.status,
      currentLoad: agent.currentLoad,
      maxCapacity: agent.maxCapacity,
      utilizationRate: agent.maxCapacity
        ? Number(((agent.currentLoad / agent.maxCapacity) * 100).toFixed(2))
        : 0,
      tickets: tickets.filter(ticket => ticket.assigneeId === agent.id).length,
      skills: agent.skills,
    }));
  }

  getAlerts(): SupervisorAlert[] {
    const alerts: SupervisorAlert[] = [];
    const now = new Date().toISOString();

    this.getQueues()
      .filter(queue => queue.health === 'critical')
      .forEach(queue => {
        alerts.push({
          id: crypto.randomUUID(),
          severity: 'critical',
          type: 'queue_overflow',
          title: `Fila ${queue.queueName} congestionada`,
          description: `Volume atual ${queue.volume} com risco de SLA ${queue.slaRisk}.`,
          createdAt: now,
        });
      });

    this.getAgents()
      .filter(agent => agent.currentLoad >= agent.maxCapacity)
      .forEach(agent => {
        alerts.push({
          id: crypto.randomUUID(),
          severity: 'warning',
          type: 'agent_overload',
          title: `Agente ${agent.name} com carga máxima`,
          description: `Carga ${agent.currentLoad}/${agent.maxCapacity}.`,
          createdAt: now,
        });
      });

    const automationFailures = this.automationService
      .listLogs()
      .filter(log => log.executionStatus === 'failed').length;

    if (automationFailures > 0) {
      alerts.push({
        id: crypto.randomUUID(),
        severity: 'warning',
        type: 'automation_failure',
        title: 'Falhas de automação detectadas',
        description: `${automationFailures} execuções com falha no período recente.`,
        createdAt: now,
      });
    }

    return alerts;
  }

  getAiMetrics() {
    const events = inMemoryEventStore.list();
    const startedByAi = events.filter(
      event => event.eventType === 'ai.answer_generated'
    ).length;
    const resolvedByAi = events.filter(
      event => event.eventType === 'ai.resolved_without_human'
    ).length;
    const handoffs = events.filter(
      event => event.eventType === 'ai.handoff_to_human'
    ).length;

    return {
      startedByAi,
      resolvedByAi,
      handoffs,
      fallbackRate: startedByAi
        ? Number(((handoffs / startedByAi) * 100).toFixed(2))
        : 0,
    };
  }

  getAutomationMetrics() {
    const logs = this.automationService.listLogs();

    return {
      activeAutomations: this.automationService
        .listAutomations()
        .filter(automation => automation.isActive).length,
      executedToday: logs.length,
      success: logs.filter(log => log.executionStatus === 'success').length,
      failed: logs.filter(log => log.executionStatus === 'failed').length,
      routedAutomatically: logs
        .filter(log =>
          log.executedActions.some(action => action.type === 'transfer_to_queue')
        )
        .length,
    };
  }

  redistribute(payload: { fromQueue: string; toQueue: string; limit: number }) {
    const tickets = inMemoryRoutingStore
      .listTickets()
      .filter(ticket => ticket.queueId === payload.fromQueue)
      .slice(0, payload.limit);

    const moved = tickets.map(ticket =>
      inMemoryRoutingStore.updateTicket(ticket.id, {
        queueId: payload.toQueue,
        assigneeId: undefined,
      })
    );

    return {
      movedCount: moved.filter(Boolean).length,
      fromQueue: payload.fromQueue,
      toQueue: payload.toQueue,
    };
  }
}
