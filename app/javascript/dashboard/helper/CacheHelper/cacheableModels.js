// Single source of truth for IDB-cached workspace config.
//
// Each entry must keep `name` equal to the Rails `Model.name.underscore` value
// so the server's `cache_keys` payload (and the IDB object store name) lines up
// with what the client looks up.
//
// `dispatchPath` is the full Vuex dispatch path for the revalidate action.
// `setMutation` is the full commit path used by hydrateStoresFromCache to seed
// Vuex from IDB. `clearMutation` (optional) is committed BEFORE `setMutation`
// for modules whose SET_* mutation merges-by-id instead of replacing — without
// it, rows deleted server-side between sessions would survive as phantoms.
export const cacheableModels = [
  {
    name: 'inbox',
    dispatchPath: 'inboxes/revalidate',
    setMutation: 'inboxes/SET_INBOXES',
  },
  {
    name: 'label',
    dispatchPath: 'labels/revalidate',
    setMutation: 'labels/SET_LABELS',
  },
  {
    name: 'team',
    dispatchPath: 'teams/revalidate',
    setMutation: 'teams/SET_TEAMS',
    clearMutation: 'teams/CLEAR_TEAMS',
  },
  {
    name: 'canned_response',
    dispatchPath: 'revalidateCannedResponses',
    setMutation: 'SET_CANNED',
  },
  {
    name: 'account_user',
    dispatchPath: 'agents/revalidate',
    setMutation: 'agents/SET_AGENTS',
  },
  {
    name: 'custom_attribute_definition',
    dispatchPath: 'attributes/revalidate',
    setMutation: 'attributes/SET_CUSTOM_ATTRIBUTE',
  },
];

export const cacheableModelNames = cacheableModels.map(model => model.name);
