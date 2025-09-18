type JsonObject = Record<string, unknown>;
type JsonArray = unknown[];
export type NetworkBody = JsonObject | JsonArray | string;
export type NetworkMetaWarning = 'MAYBE_JSON_TRUNCATED' | 'TEXT_TRUNCATED' | 'URL_SKIPPED' | 'BODY_PARSE_ERROR' | 'UNPARSEABLE_BODY_TYPE';
interface NetworkMeta {
    warnings?: NetworkMetaWarning[];
}
export interface ReplayNetworkRequestOrResponse {
    size?: number;
    body?: NetworkBody;
    headers: Record<string, string>;
    _meta?: NetworkMeta;
}
export {};
//# sourceMappingURL=request.d.ts.map