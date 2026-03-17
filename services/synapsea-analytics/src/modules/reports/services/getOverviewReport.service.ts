import type { OverviewFilters } from '../types/report.types.js';
import { OverviewReportRepository } from '../repositories/overviewReport.repository.js';

export class GetOverviewReportService {
  constructor(private readonly repository = new OverviewReportRepository()) {}

  async execute(filters: OverviewFilters) {
    return this.repository.getOverview(filters);
  }
}
