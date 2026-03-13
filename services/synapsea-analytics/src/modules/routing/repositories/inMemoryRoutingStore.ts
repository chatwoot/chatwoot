import type { Agent, Queue, Ticket, TicketTransfer } from '../types/routing.types.js';

const queues: Queue[] = [
  {
    id: 'q-general',
    name: 'General Queue',
    department: 'general',
    priority: 'normal',
    maxCapacity: 999,
  },
  {
    id: 'q-finance',
    name: 'Financeiro',
    department: 'financeiro',
    priority: 'high',
    maxCapacity: 120,
  },
  {
    id: 'q-support-n1',
    name: 'Suporte N1',
    department: 'suporte_n1',
    priority: 'normal',
    maxCapacity: 180,
  },
  {
    id: 'q-sales',
    name: 'Comercial',
    department: 'comercial',
    priority: 'normal',
    maxCapacity: 160,
  },
];

const agents: Agent[] = [
  {
    id: 'a-maria',
    name: 'Maria',
    skills: ['financeiro', 'cobranca'],
    status: 'available',
    maxCapacity: 10,
    currentLoad: 4,
  },
  {
    id: 'a-joao',
    name: 'João',
    skills: ['suporte', 'implantacao'],
    status: 'available',
    maxCapacity: 12,
    currentLoad: 5,
  },
  {
    id: 'a-pedro',
    name: 'Pedro',
    skills: ['vendas', 'comercial'],
    status: 'attending',
    maxCapacity: 10,
    currentLoad: 8,
  },
];

const tickets: Ticket[] = [];
const transfers: TicketTransfer[] = [];

export const inMemoryRoutingStore = {
  listQueues: () => [...queues],
  listAgents: () => [...agents],
  listTickets: () => [...tickets],
  listTransfers: () => [...transfers],
  getTicketById: (id: string) => tickets.find(ticket => ticket.id === id),
  addTicket: (ticket: Ticket) => {
    tickets.push(ticket);
    return ticket;
  },
  updateTicket: (ticketId: string, patch: Partial<Ticket>) => {
    const index = tickets.findIndex(ticket => ticket.id === ticketId);
    if (index === -1) return undefined;

    tickets[index] = { ...tickets[index], ...patch };
    return tickets[index];
  },
  findQueueById: (queueId: string) => queues.find(queue => queue.id === queueId),
  findAgentById: (agentId: string) => agents.find(agent => agent.id === agentId),
  updateAgent: (agentId: string, patch: Partial<Agent>) => {
    const index = agents.findIndex(agent => agent.id === agentId);
    if (index === -1) return undefined;

    agents[index] = { ...agents[index], ...patch };
    return agents[index];
  },
  addTransfer: (transfer: TicketTransfer) => {
    transfers.push(transfer);
    return transfer;
  },
};
