export type AnalyticalIntent =
  | 'overview'
  | 'sla_analysis'
  | 'agent_performance'
  | 'lead_conversion'
  | 'ai_efficiency';

export class ClassifyQuestionService {
  execute(question: string): AnalyticalIntent {
    const q = question.toLowerCase();

    if (q.includes('sla')) return 'sla_analysis';
    if (q.includes('atendente') || q.includes('operador')) {
      return 'agent_performance';
    }
    if (q.includes('lead') || q.includes('conversão')) return 'lead_conversion';
    if (q.includes('ia') || q.includes('handoff')) return 'ai_efficiency';

    return 'overview';
  }
}
