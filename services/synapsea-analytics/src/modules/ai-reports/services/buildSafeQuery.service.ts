import { METRICS_CATALOG } from '../../../lib/metricsCatalog.js';
import type { AnalyticalIntent } from './classifyQuestion.service.js';

const INTENT_METRICS: Record<AnalyticalIntent, Array<keyof typeof METRICS_CATALOG>> = {
  overview: ['totalConversations', 'avgFirstResponseSeconds', 'avgResolutionSeconds'],
  sla_analysis: ['slaBreachRate', 'avgFirstResponseSeconds'],
  agent_performance: ['totalConversations', 'avgResolutionSeconds'],
  lead_conversion: ['totalConversations'],
  ai_efficiency: ['aiResolutionRate'],
};

export class BuildSafeQueryService {
  execute(intent: AnalyticalIntent) {
    return {
      metrics: INTENT_METRICS[intent],
      strategy: 'template_query',
    };
  }
}
