/* global axios */

import { DataManager } from './DataManager';
import { cacheableModels } from './cacheableModels';

// Seed Vuex from IndexedDB before the dashboard renders, then reconcile
// against the server's authoritative cache keys in the background.
//
// CRITICAL ORDERING: capture local cache keys BEFORE fetching server keys.
// Each per-model `revalidate` action calls `validateCacheKey(newKey)`, which
// compares `newKey` against whatever is currently persisted in IDB. If we
// wrote the server keys first, that comparison would return true against the
// just-written key and stale IDB data would be served forever.
export default async function hydrateStoresFromCache(store, accountId) {
  let dm;
  try {
    dm = new DataManager(accountId);
    await dm.initDb();
  } catch {
    // IDB unsupported (e.g. Firefox private mode) — silent no-op. Components
    // will fetch from the network normally via the cache-enabled API client.
    return;
  }

  // 1. Snapshot local cache keys before any server interaction.
  const localKeys = {};
  await Promise.all(
    cacheableModels.map(async model => {
      localKeys[model.name] = await dm.getCacheKey(model.name);
    })
  );

  // 2. Stale-while-revalidate paint: commit cached data into Vuex immediately.
  await Promise.all(
    cacheableModels.map(async model => {
      const localData = await dm.get({ modelName: model.name });
      if (localData.length === 0) return;
      if (model.clearMutation) store.commit(model.clearMutation);
      store.commit(model.setMutation, localData);
    })
  );

  // 3. Fetch the server's authoritative cache keys once.
  let serverKeys;
  try {
    const { data } = await axios.get(
      `/api/v1/accounts/${accountId}/cache_keys`
    );
    serverKeys = data.cache_keys || {};
  } catch {
    return;
  }

  // 4. For each stale model, dispatch revalidate with the NEW server key.
  //    Do NOT await — the UI is already painted with stale data; refetches
  //    swap it in as they complete.
  //
  //    Skip models with no local cache key — they've never been fetched on
  //    this device. The first downstream component that dispatches
  //    `<store>/get` will network-fetch via the cache-enabled API client
  //    and populate IDB. Boot stays cheap on cold devices.
  cacheableModels.forEach(model => {
    const serverKey = serverKeys[model.name];
    if (serverKey === undefined) return;
    const localKey = localKeys[model.name];
    if (localKey === undefined) return;
    if (serverKey === localKey) return;
    store.dispatch(model.dispatchPath, { newKey: serverKey });
  });
}
