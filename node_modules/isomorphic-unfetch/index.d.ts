import {
  Body as NodeBody,
  Headers as NodeHeaders,
  Request as NodeRequest,
  Response as NodeResponse,
  RequestInit as NodeRequestInit
} from "node-fetch";

declare namespace unfetch {
  export type IsomorphicHeaders = Headers | NodeHeaders;
  export type IsomorphicBody = Body | NodeBody;
  export type IsomorphicResponse = Response | NodeResponse;
  export type IsomorphicRequest = Request | NodeRequest;
  export type IsomorphicRequestInit = RequestInit | NodeRequestInit;
}

declare const unfetch: typeof fetch;

export default unfetch;
