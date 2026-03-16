import { inMemoryRoutingStore } from '../repositories/inMemoryRoutingStore.js';
import type { Agent, Ticket } from '../types/routing.types.js';

const CHANNEL_WEIGHTS: Record<string, number> = {
  whatsapp: 3,
  email: 1,
  chat: 2,
  cobranca: 2,
  implantacao: 5,
};

const TRIAGE_RULES: Array<{ keyword: string; queueId: string; skill: string }> = [
  { keyword: 'boleto', queueId: 'q-finance', skill: 'financeiro' },
  { keyword: 'cobran', queueId: 'q-finance', skill: 'cobranca' },
  { keyword: 'implanta', queueId: 'q-support-n1', skill: 'implantacao' },
  { keyword: 'comprar', queueId: 'q-sales', skill: 'vendas' },
];

const isEligibleStatus = (status: Agent['status']) =>
  ['available', 'attending'].includes(status);

const resolveWeight = (message: string) => {
  const lowerMessage = message.toLowerCase();
  const matchedWeight = Object.entries(CHANNEL_WEIGHTS).find(([key]) =>
    lowerMessage.includes(key)
  );

  return matchedWeight ? matchedWeight[1] : 2;
};

export class RoutingService {
  triageTicket(message: string) {
    const normalized = message.toLowerCase();
    const matchedRule = TRIAGE_RULES.find(rule => normalized.includes(rule.keyword));

    if (!matchedRule) {
      return {
        queueId: 'q-general',
        requiredSkill: 'suporte',
        priority: 'normal' as const,
      };
    }

    return {
      queueId: matchedRule.queueId,
      requiredSkill: matchedRule.skill,
      priority: matchedRule.queueId === 'q-finance' ? ('high' as const) : ('normal' as const),
    };
  }

  routeBySkillAndCapacity(requiredSkill: string, message: string) {
    const weight = resolveWeight(message);

    const eligibleAgents = inMemoryRoutingStore
      .listAgents()
      .filter(
        agent =>
          agent.skills.includes(requiredSkill) &&
          isEligibleStatus(agent.status) &&
          agent.currentLoad + weight <= agent.maxCapacity
      )
      .sort((a, b) => a.currentLoad - b.currentLoad);

    const bestAgent = eligibleAgents[0];
    if (!bestAgent) return undefined;

    inMemoryRoutingStore.updateAgent(bestAgent.id, {
      currentLoad: bestAgent.currentLoad + weight,
      status: 'attending',
    });

    return {
      agentId: bestAgent.id,
      routedWeight: weight,
    };
  }

  createTicket(payload: { subject: string; message: string }) {
    const triage = this.triageTicket(payload.message);
    const route = this.routeBySkillAndCapacity(triage.requiredSkill, payload.message);

    const ticket: Ticket = {
      id: crypto.randomUUID(),
      subject: payload.subject,
      message: payload.message,
      queueId: triage.queueId,
      requiredSkill: triage.requiredSkill,
      priority: triage.priority,
      assigneeId: route?.agentId,
      status: 'open',
      createdAt: new Date().toISOString(),
    };

    return inMemoryRoutingStore.addTicket(ticket);
  }

  transferTicket(ticketId: string, payload: { toAgentId?: string; toQueueId?: string; reason: string; summary?: string; nextStep?: string; }) {
    const ticket = inMemoryRoutingStore.getTicketById(ticketId);
    if (!ticket) return undefined;

    const transfer = inMemoryRoutingStore.addTransfer({
      id: crypto.randomUUID(),
      ticketId,
      fromAgent: ticket.assigneeId,
      toAgent: payload.toAgentId,
      fromQueue: ticket.queueId,
      toQueue: payload.toQueueId,
      reason: payload.reason,
      summary: payload.summary,
      nextStep: payload.nextStep,
      createdAt: new Date().toISOString(),
    });

    inMemoryRoutingStore.updateTicket(ticketId, {
      assigneeId: payload.toAgentId ?? ticket.assigneeId,
      queueId: payload.toQueueId ?? ticket.queueId,
    });

    return transfer;
  }

  assignTicket(ticketId: string, assigneeId: string) {
    return inMemoryRoutingStore.updateTicket(ticketId, { assigneeId });
  }

  enqueueTicket(ticketId: string, queueId: string) {
    return inMemoryRoutingStore.updateTicket(ticketId, {
      queueId,
      assigneeId: undefined,
    });
  }

  escalateTicket(ticketId: string, reason: string) {
    const ticket = inMemoryRoutingStore.getTicketById(ticketId);
    if (!ticket) return undefined;

    inMemoryRoutingStore.updateTicket(ticketId, { priority: 'urgent' });

    return inMemoryRoutingStore.addTransfer({
      id: crypto.randomUUID(),
      ticketId,
      fromAgent: ticket.assigneeId,
      fromQueue: ticket.queueId,
      toQueue: ticket.queueId,
      reason,
      summary: 'Auto escalation to specialist flow',
      createdAt: new Date().toISOString(),
    });
  }

  getQueueHeatmap() {
    const tickets = inMemoryRoutingStore.listTickets();
    const queueGroups = inMemoryRoutingStore.listQueues().map(queue => {
      const queueTickets = tickets.filter(ticket => ticket.queueId === queue.id);
      const slaRisk = queueTickets.filter(ticket => ticket.priority === 'urgent').length;

      return {
        queueId: queue.id,
        queueName: queue.name,
        department: queue.department,
        volume: queueTickets.length,
        slaRisk,
      };
    });

    return queueGroups;
  }

  getWorkloadByAgent() {
    const agents = inMemoryRoutingStore.listAgents();
    return agents.map(agent => ({
      agentId: agent.id,
      name: agent.name,
      tickets: inMemoryRoutingStore
        .listTickets()
        .filter(ticket => ticket.assigneeId === agent.id).length,
      currentLoad: agent.currentLoad,
      maxCapacity: agent.maxCapacity,
      status: agent.status,
    }));
  }
}
