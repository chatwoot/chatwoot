import { APIRequestContext } from '@playwright/test';
import { APILogger } from '@utils/logger';

export class RequestHandler {
  private requestContext: APIRequestContext;
  private baseUrl!: string;
  private defaultBaseUrl: string;
  private apiPath: string = '';
  private queryParams: object = {};
  private apiHeaders: Record<string, string> = {};
  private apiBody: object = {};
  private logger: APILogger;
  private logsEnabled: boolean = false;
  private clearAuthFlag: boolean = false;

  constructor(request: APIRequestContext, apiBaseUrl: string, logger: APILogger) {
    this.requestContext = request;
    this.defaultBaseUrl = apiBaseUrl;
    this.logger = logger;
  }

  private statusCodeValidator(actualStatus: number, expectStatus: number, callingMethod: Function) {
    if (actualStatus !== expectStatus) {
      const logs = this.logger.getRecentLogs();
      const error = new Error(`Expected status ${expectStatus} Actual status ${actualStatus}\n\n API Request: \n${logs}`);
      Error.captureStackTrace(error, callingMethod);
      throw error;
    }
  }

  private cleanupFields() {
    this.apiBody = {};
    this.apiHeaders = {};
    this.baseUrl = undefined;
    this.apiPath = '';
    this.queryParams = {};
    this.clearAuthFlag = false;
  }

  url(url: string) {
    this.baseUrl = url;
    return this;
  }
  path(path: string) {
    this.apiPath = path;
    return this;
  }
  params(params: object) {
    this.queryParams = params;
    return this;
  }
  headers(headers: Record<string, string>) {
    this.apiHeaders = headers;
    return this;
  }
  body(body: object) {
    this.apiBody = body;
    return this;
  }
  logs(enabled: boolean) {
    this.logsEnabled = enabled;
    return this;
  }

  async request(method: 'GET' | 'POST' | 'PUT' | 'DELETE', statusCode: number, includeHeaders: boolean = false) {
    const url = this.getUrl();
    if (this.logsEnabled) {
      this.logger.logRequest(method, url, this.apiHeaders, method !== 'GET' ? this.apiBody : undefined);
    }

    const requestMethod = this.requestContext[method.toLowerCase() as 'get' | 'post' | 'put' | 'delete'];
    const response = await requestMethod.call(this.requestContext, url, {
      headers: this.apiHeaders,
      ...(method !== 'GET' && { data: this.apiBody }),
    });

    this.cleanupFields();
    const actualStatus = response.status();
    let data;

    try {
      data = await response.json();
    } catch (error) {
      const text = await response.text();
      const logs = this.logger.getRecentLogs();
      throw new Error(`Failed to parse response as JSON for ${method} ${url}\nStatus: ${actualStatus}\n\nResponse body:\n${text}\n\nAPI Request:\n${logs}`);
    }

    if (this.logsEnabled) {
      this.logger.logResponse(actualStatus, data);
    }
    this.statusCodeValidator(actualStatus, statusCode, this.request);

    if (includeHeaders) {
      const headers = response.headers();
      return { data, headers };
    }

    return data;
  }

  async getRequest(statusCode: number) {
    return this.request('GET', statusCode);
  }

  async postRequest(statusCode: number) {
    return this.request('POST', statusCode);
  }

  async postRequestWithHeaders(statusCode: number) {
    return this.request('POST', statusCode, true);
  }

  async putRequest(statusCode: number) {
    return this.request('PUT', statusCode);
  }

  async putRequestWithHeaders(statusCode: number) {
    return this.request('PUT', statusCode, true);
  }

  async deleteRequest(statusCode: number) {
    return this.request('DELETE', statusCode);
  }

  private getUrl() {
    const url = new URL(
      `${this.baseUrl ?? this.defaultBaseUrl}${this.apiPath}`
    );

    for (const [key, value] of Object.entries(this.queryParams)) {
      url.searchParams.append(key, value);
    }
    return url.toString();
  }
}
