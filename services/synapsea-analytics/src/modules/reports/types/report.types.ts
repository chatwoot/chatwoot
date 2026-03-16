export type OverviewFilters = {
  dateFrom: string;
  dateTo: string;
  inboxIds?: string[];
};

export type OverviewReport = {
  totalConversations: number;
  avgFirstResponseSeconds: number;
  avgResolutionSeconds: number;
  slaFirstResponseRate: number;
  slaResolutionRate: number;
  aiResolutionRate: number;
};
