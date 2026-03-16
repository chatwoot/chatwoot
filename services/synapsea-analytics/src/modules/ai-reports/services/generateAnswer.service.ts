import type { AskAiReportInput, AskAiReportOutput } from '../types/aiReport.types.js';
import { ClassifyQuestionService } from './classifyQuestion.service.js';
import { BuildSafeQueryService } from './buildSafeQuery.service.js';
import { GetOverviewReportService } from '../../reports/services/getOverviewReport.service.js';

const defaultDateRange = () => {
  const now = new Date();
  const from = new Date(now);
  from.setDate(now.getDate() - 7);

  return {
    dateFrom: from.toISOString(),
    dateTo: now.toISOString(),
  };
};

export class GenerateAnswerService {
  private readonly classifier = new ClassifyQuestionService();
  private readonly safeQueryBuilder = new BuildSafeQueryService();
  private readonly overviewService = new GetOverviewReportService();

  async execute(input: AskAiReportInput): Promise<AskAiReportOutput> {
    const intent = this.classifier.execute(input.question);
    const queryPlan = this.safeQueryBuilder.execute(intent);

    const range = {
      ...defaultDateRange(),
      ...input.filters,
    };

    const overview = await this.overviewService.execute({
      dateFrom: range.dateFrom || defaultDateRange().dateFrom,
      dateTo: range.dateTo || defaultDateRange().dateTo,
      inboxIds: range.inboxIds,
    });

    return {
      summary: `Resumo executivo: ${overview.totalConversations} conversas no período, SLA de primeira resposta em ${overview.slaFirstResponseRate}% e resolução por IA em ${overview.aiResolutionRate}%.`,
      insights: [
        `A pergunta foi classificada como ${intent}.`,
        `Métricas permitidas usadas: ${queryPlan.metrics.join(', ')}.`,
      ],
      recommendations: [
        'Monitorar tendências de SLA por setor e horário.',
        'Automatizar temas com maior volume e baixa resolução.',
      ],
      data: {
        totalConversations: overview.totalConversations,
        slaFirstResponseRate: overview.slaFirstResponseRate,
        slaResolutionRate: overview.slaResolutionRate,
        aiResolutionRate: overview.aiResolutionRate,
      },
    };
  }
}
