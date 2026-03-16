export type AskAiReportInput = {
  question: string;
  filters?: {
    dateFrom?: string;
    dateTo?: string;
    inboxIds?: string[];
  };
};

export type AskAiReportOutput = {
  summary: string;
  insights: string[];
  recommendations: string[];
  data: Record<string, number>;
};
