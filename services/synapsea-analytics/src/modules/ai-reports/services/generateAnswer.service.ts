import type { AskAiReportInput, AskAiReportOutput } from '../types/aiReport.types.js';
import { ClassifyQuestionService } from './classifyQuestion.service.js';
import { BuildSafeQueryService } from './buildSafeQuery.service.js';

export class GenerateAnswerService {
  private readonly classifier = new ClassifyQuestionService();
  private readonly safeQueryBuilder = new BuildSafeQueryService();

  execute(input: AskAiReportInput): AskAiReportOutput {
    const intent = this.classifier.execute(input.question);
    const queryPlan = this.safeQueryBuilder.execute(intent);

    return {
      summary: `Análise gerada para intenção ${intent} com consultas seguras por template.`,
      insights: [
        'Concentre o monitoramento nos indicadores oficiais do catálogo de métricas.',
        `Métricas consultadas: ${queryPlan.metrics.join(', ')}.`,
      ],
      recommendations: [
        'Acompanhar variação diária por inbox e por setor.',
        'Configurar alertas automáticos para desvios de SLA.',
      ],
      data: {
        totalConversations: 0,
      },
    };
  }
}
