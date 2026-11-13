type LogEntry = {
  type: 'Request Details' | 'Response Details';
  data: unknown;
};

export class APILogger {
  private recentLogs: LogEntry[] = [];

  logRequest(method: string, url: string, headers: Record<string, string>, body?: unknown) {
    const logEntry = { method, url, headers, body };
    this.recentLogs.push({ type: 'Request Details', data: logEntry });
  }

  logResponse(statusCode: number, body?: unknown) {
    const logEntry = { statusCode, body };
    this.recentLogs.push({ type: 'Response Details', data: logEntry });
  }

  getRecentLogs() {
    const logs = this.recentLogs
      .map(log => `===${log.type}===\n${JSON.stringify(log.data, null, 4)}`)
      .join('\n\n');
    return logs;
  }
}
