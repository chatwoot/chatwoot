export type AgentStatus =
  | 'available'
  | 'attending'
  | 'after_call'
  | 'short_break'
  | 'lunch'
  | 'training'
  | 'backoffice'
  | 'offline';

export type Queue = {
  id: string;
  name: string;
  department: string;
  priority: 'low' | 'normal' | 'high' | 'critical';
  maxCapacity: number;
};

export type Agent = {
  id: string;
  name: string;
  skills: string[];
  status: AgentStatus;
  maxCapacity: number;
  currentLoad: number;
};

export type Ticket = {
  id: string;
  subject: string;
  message: string;
  queueId: string;
  status: 'open' | 'pending' | 'resolved';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  assigneeId?: string;
  requiredSkill?: string;
  createdAt: string;
};

export type TicketTransfer = {
  id: string;
  ticketId: string;
  fromAgent?: string;
  toAgent?: string;
  fromQueue?: string;
  toQueue?: string;
  reason: string;
  summary?: string;
  nextStep?: string;
  createdAt: string;
};
