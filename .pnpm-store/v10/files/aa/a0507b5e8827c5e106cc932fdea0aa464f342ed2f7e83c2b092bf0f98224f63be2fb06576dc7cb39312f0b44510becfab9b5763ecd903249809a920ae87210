export type FetchCall = [input: RequestInfo, init?: RequestInit | undefined]

export const parseFetchCall = ([url, request]: FetchCall) => ({
  url,
  method: request?.method,
  headers: request?.headers,
  body: request?.body ? JSON.parse(request.body as any) : undefined,
})
