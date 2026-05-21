// Bump DATA_VERSION whenever a new object store is added to the IDB schema
// (the `upgrade()` callback in DataManager only runs when the stored DB
// version is less than the requested version). The upgrade body itself is
// idempotent — it conditionally creates each store via
// `objectStoreNames.contains(name)` — so a single bump is enough to add any
// number of new stores without losing existing data.
//
// Wednesday, 21 May 2026 — bumped to add canned_response + account_user stores
export const DATA_VERSION = '1747785600';
