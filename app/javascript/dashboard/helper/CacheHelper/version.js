// Bump DATA_VERSION to (a) add new object stores to the IDB schema or (b)
// flush bad/stale cache globally. The `upgrade()` callback in DataManager runs
// only when the stored DB version is less than the requested version; on any
// such bump it clears every existing store (a full cache reset) and then
// idempotently creates any missing stores. So bump this whenever a cached
// model's serializer shape changes, or to force all clients to refetch.
//
// Thursday, 28 May 2026 — bumped to add canned_response + account_user stores + custom_attribute_definition store
export const DATA_VERSION = '1748390400';
