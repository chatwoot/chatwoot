import type { OverviewFilters, OverviewReport } from '../types/report.types.js';

export class OverviewReportRepository {
  async getOverview(_filters: OverviewFilters): Promise<OverviewReport> {
    return {
      totalConversations: 0,
      avgFirstResponseSeconds: 0,
      avgResolutionSeconds: 0,
      slaFirstResponseRate: 0,
      slaResolutionRate: 0,
      aiResolutionRate: 0,
    };
  }
}
