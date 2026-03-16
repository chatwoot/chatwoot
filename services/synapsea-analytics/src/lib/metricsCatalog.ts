export const METRICS_CATALOG = {
  totalConversations: {
    label: 'Total de conversas',
    table: 'fact_conversations',
    aggregation: 'count',
  },
  avgFirstResponseSeconds: {
    label: 'Tempo médio de primeira resposta',
    table: 'fact_conversations',
    aggregation: 'avg',
  },
  avgResolutionSeconds: {
    label: 'Tempo médio de resolução',
    table: 'fact_conversations',
    aggregation: 'avg',
  },
  slaBreachRate: {
    label: 'Taxa de violação de SLA',
    table: 'fact_sla_events',
    aggregation: 'ratio',
  },
  aiResolutionRate: {
    label: 'Taxa de resolução pela IA',
    table: 'fact_ai_usage',
    aggregation: 'ratio',
  },
} as const;
