import type { AskAiReportInput, AskAiReportOutput } from '../types/aiReport.types.js';
import { ClassifyQuestionService } from './classifyQuestion.service.js';
import { BuildSafeQueryService } from './buildSafeQuery.service.js';
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt

 codex/transform-chatwoot-into-synapsea-connect-vkjace

 codex/transform-chatwoot-into-synapsea-connect-ymy4px

 codex/transform-chatwoot-into-synapsea-connect-nhivec
 develop
 develop
 develop
 develop
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

 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
export class GenerateAnswerService {
  private readonly classifier = new ClassifyQuestionService();
  private readonly safeQueryBuilder = new BuildSafeQueryService();

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
export class GenerateAnswerService {
  private readonly classifier = new ClassifyQuestionService();
  private readonly safeQueryBuilder = new BuildSafeQueryService();

 codex/transform-chatwoot-into-synapsea-connect-vkjace
export class GenerateAnswerService {
  private readonly classifier = new ClassifyQuestionService();
  private readonly safeQueryBuilder = new BuildSafeQueryService();

 codex/transform-chatwoot-into-synapsea-connect-ymy4px
export class GenerateAnswerService {
  private readonly classifier = new ClassifyQuestionService();
  private readonly safeQueryBuilder = new BuildSafeQueryService();

 develop

export class GenerateAnswerService {
  private readonly classifier = new ClassifyQuestionService();
  private readonly safeQueryBuilder = new BuildSafeQueryService();
 codex/transform-chatwoot-into-synapsea-connect-nhivec
 develop
 develop
 develop
 develop
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
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt

 codex/transform-chatwoot-into-synapsea-connect-vkjace

 codex/transform-chatwoot-into-synapsea-connect-ymy4px



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
 develop
 develop
 develop
 develop
 develop
      },
    };
  }
}
