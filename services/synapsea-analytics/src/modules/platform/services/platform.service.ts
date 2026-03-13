import type { CanonicalEvent, PlatformBlueprint } from '../types/platform.types.js';

const CANONICAL_EVENTS: CanonicalEvent[] = [
  {
    type: 'conversation.created',
    category: 'conversation',
    producer: 'operations-service',
    consumers: ['routing-engine', 'analytics-engine', 'notification-engine'],
  },
  {
    type: 'conversation.transferred',
    category: 'routing',
    producer: 'routing-engine',
    consumers: ['analytics-engine', 'supervisor-service', 'automation-engine'],
  },
  {
    type: 'message.received',
    category: 'message',
    producer: 'operations-service',
    consumers: ['automation-engine', 'ai-assistant', 'analytics-engine'],
  },
  {
    type: 'sla.risk',
    category: 'sla',
    producer: 'supervisor-service',
    consumers: ['notification-engine', 'automation-engine', 'routing-engine'],
  },
  {
    type: 'automation.executed',
    category: 'automation',
    producer: 'automation-engine',
    consumers: ['analytics-engine', 'supervisor-service'],
  },
  {
    type: 'ai.handoff',
    category: 'ai',
    producer: 'ai-assistant',
    consumers: ['routing-engine', 'analytics-engine', 'operations-service'],
  },
  {
    type: 'lead.qualified',
    category: 'lead',
    producer: 'sdr-service',
    consumers: ['analytics-engine', 'operations-service', 'notification-engine'],
  },
];

const BLUEPRINT: PlatformBlueprint = {
  architecture: 'event-driven-modular',
  layers: [
    {
      name: 'experience',
      description: 'Agent cockpit, supervisor tower, reports, automation and SDR workspaces.',
    },
    {
      name: 'orchestration',
      description: 'Routing, SLA, automation and permissions as operational decision layer.',
    },
    {
      name: 'intelligence',
      description: 'AI summarization, qualification, recommendations and narrative reports.',
    },
    {
      name: 'data',
      description: 'Operational Postgres, analytical marts, event store and vector memory.',
    },
  ],
  services: [
    {
      name: 'operations-service',
      responsibility: 'Conversations, tickets, contacts, tags, notes and assignments.',
      endpoints: ['/conversations', '/tickets', '/contacts'],
    },
    {
      name: 'routing-engine',
      responsibility: 'Capacity/skill routing, enqueue, transfer and escalation.',
      endpoints: ['/api/tickets', '/api/routing/queues/heatmap', '/api/routing/workload'],
    },
    {
      name: 'automation-engine',
      responsibility: 'Trigger-condition-action execution with cooldown and logs.',
      endpoints: ['/api/automations', '/api/automations/test', '/api/automations/logs'],
    },
    {
      name: 'ai-assistant',
      responsibility: 'Summary, intent, recommendations and AI report answers.',
      endpoints: ['/api/reports/ask-ai'],
    },
    {
      name: 'supervisor-service',
      responsibility: 'Real-time operational visibility and rapid redistribution.',
      endpoints: ['/api/supervisor/overview', '/api/supervisor/alerts', '/api/supervisor/redistribute'],
    },
    {
      name: 'sdr-service',
      responsibility: 'Lead import, autonomous outreach, qualification and commercial metrics.',
      endpoints: ['/api/leads/import', '/api/sdr/start', '/api/sdr/metrics'],
    },
  ],
  realtime: {
    transport: 'websocket',
    channels: ['tenant:*', 'queue:*', 'agent:*', 'supervisor:*'],
  },
};

export class PlatformService {
  getBlueprint() {
    return BLUEPRINT;
  }

  listCanonicalEvents() {
    return CANONICAL_EVENTS;
  }
}
