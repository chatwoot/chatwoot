import AutonomiaSourcesAPI from '../../api/autonomia/sources';
import { throwErrorMessage } from 'dashboard/store/utils/api';

// Knowledge sources are a per-agent sub-resource (no global records-by-id list),
// so this module is hand-rolled rather than using the CRUD factory. State holds
// the source list for the currently viewed agent; switching agents refetches.
//
// Ingestion is asynchronous (IngestJob): a freshly created/re-synced source is
// `pending`/`processing` and only flips to `ready`/`failed` later. We poll
// `fetch` while any source is still ingesting so the UI reflects progress.
const POLL_INTERVAL = 4000;
const INGESTING_STATUSES = ['pending', 'processing'];

let pollTimer = null;

// A source is still "settling" while it ingests (pending/processing) OR while it
// has finished ingesting (`ready`) but the quality review has not landed yet
// (`review.status == null`). The Revisor runs after ingestion, so a `ready`
// source with no review is still in flight as far as the Materiais UI cares.
const isIngesting = source =>
  INGESTING_STATUSES.includes(source?.status) ||
  (source?.status === 'ready' && source?.review?.status == null);

export const state = {
  records: [],
  uiFlags: {
    fetchingList: false,
    creatingItem: false,
    deletingItem: false,
    resyncingItem: false,
  },
};

export const getters = {
  getSources($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  // "O que ela sabe" — documents/links that become RAG knowledge. Defaults to
  // `knowledge` so payloads without the `kind` column (backend gap #2) all land
  // in the first tab.
  getKnowledgeSources($state) {
    return $state.records.filter(
      record => (record.kind ?? 'knowledge') === 'knowledge'
    );
  },
  // "O que ela pode enviar" — media the agent forwards to customers. Empty until
  // the backend serializes `kind: 'media'`.
  getMediaSources($state) {
    return $state.records.filter(record => record.kind === 'media');
  },
  // Whether the payload carries the saber/enviar `kind` split at all; gates the
  // second tab so we render a single tab until the backend ships gap #2.
  hasMediaKind($state) {
    return $state.records.some(record => record.kind != null);
  },
  // Any source the Revisor flagged for re-upload blocks "Continuar".
  getNeedsResend($state) {
    return $state.records.some(
      record => record.review?.status === 'needs_resend'
    );
  },
  // A source whose ingestion failed (`status: 'failed'`) never gets a review
  // verdict, so it would silently keep "Continuar" disabled forever via
  // getAllReviewed. Surface it like a resend so the UI can explain why the user
  // is stuck (the card offers Reenviar). Keeps the gate honest.
  getHasFailed($state) {
    return $state.records.some(record => record.status === 'failed');
  },
  // Anything that needs the user's attention before the step can close: a
  // Revisor resend request OR a hard ingestion failure. Drives the "why is
  // Continuar disabled" banner.
  getNeedsAttention($state, $getters) {
    return $getters.getNeedsResend || $getters.getHasFailed;
  },
  // Every source has settled into an acceptable verdict (accepted, or low-
  // confidence-but-usable needs_review). Empty list = nothing to gate on.
  getAllReviewed($state) {
    return (
      $state.records.length > 0 &&
      $state.records.every(record =>
        ['accepted', 'needs_review'].includes(record.review?.status)
      )
    );
  },
};

const upsertItem = (items, item) => {
  const index = items.findIndex(existing => existing.id === item.id);
  if (index === -1) return [item, ...items];
  return items.map(existing => (existing.id === item.id ? item : existing));
};

export const actions = {
  fetch: async ({ commit, dispatch }, { agentId }) => {
    // Zera a lista antes de buscar: ao trocar de agente o painel remonta, mas o
    // store é module-wide — sem isto os itens do agente anterior ficam visíveis
    // (o guard de loading é `fetchingList && !sources.length`) até o fetch voltar.
    commit('SET', []);
    commit('SET_UI_FLAG', { fetchingList: true });
    try {
      const { data } = await AutonomiaSourcesAPI.get(agentId);
      const records = data.payload || data || [];
      commit('SET', records);
      dispatch('schedulePoll', { agentId, records });
      return records;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { fetchingList: false });
    }
  },

  // `descriptor` is { url } for a link or { file } for an upload; the API
  // client maps it to the backend `source[...]` contract.
  create: async ({ commit, dispatch }, { agentId, descriptor }) => {
    commit('SET_UI_FLAG', { creatingItem: true });
    try {
      const { data } = await AutonomiaSourcesAPI.create(agentId, descriptor);
      const source = data.payload || data;
      commit('UPSERT', source);
      dispatch('schedulePoll', { agentId, records: [source] });
      return source;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { creatingItem: false });
    }
  },

  remove: async ({ commit }, { agentId, sourceId }) => {
    commit('SET_UI_FLAG', { deletingItem: true });
    try {
      await AutonomiaSourcesAPI.delete(agentId, sourceId);
      commit('DELETE', sourceId);
      return sourceId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { deletingItem: false });
    }
  },

  resync: async ({ commit, dispatch }, { agentId, sourceId }) => {
    commit('SET_UI_FLAG', { resyncingItem: true });
    try {
      const { data } = await AutonomiaSourcesAPI.resync(agentId, sourceId);
      const source = data.payload || data;
      commit('UPSERT', source);
      dispatch('schedulePoll', { agentId, records: [source] });
      return source;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { resyncingItem: false });
    }
  },

  // Starts a single polling loop while any source is still ingesting; clears
  // itself once everything settles. Idempotent: never stacks timers.
  schedulePoll: ({ dispatch }, { agentId, records = [] }) => {
    if (pollTimer || !records.some(isIngesting)) return;
    pollTimer = setTimeout(async () => {
      pollTimer = null;
      await dispatch('fetch', { agentId });
    }, POLL_INTERVAL);
  },

  stopPolling: () => {
    if (pollTimer) {
      clearTimeout(pollTimer);
      pollTimer = null;
    }
  },
};

export const mutations = {
  SET_UI_FLAG($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
  SET($state, records) {
    $state.records = records || [];
  },
  UPSERT($state, source) {
    $state.records = upsertItem($state.records || [], source);
  },
  DELETE($state, sourceId) {
    $state.records = ($state.records || []).filter(
      source => source.id !== sourceId
    );
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
