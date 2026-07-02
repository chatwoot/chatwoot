import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import types from '../mutation-types';
import CrmKanbanAPI from '../../api/crmKanban';

const emptyBoard = () => ({ pipeline: null, stages: [] });

// Single source of truth for the board filter shape. Store state,
// normalizeFilters, clearFilters (page) and any future filter UI must derive
// from this object so adding/removing a filter is a one-line change.
// NOTE: `status` was intentionally removed from the board filters. The List-only
// "Resultado" filter lives under a DISTINCT param key (`result`) and is honored
// only by Crm::Cards::FilterQuery (the list/index path); the board strips it (see
// fetchBoard) and stays strictly open-only. Do not reintroduce `status` here.
export const defaultFilters = () => ({
  search: '',
  inboxId: '',
  ownerId: '',
  priority: '',
  standalone: '',
  followUpStatus: '',
  // Default the List to in-funnel deals ('open' card status, NOT conversation
  // status). The board ignores `result` (fetchBoard strips it), so this only
  // shapes the List default — surfaced by the status tabs in the list toolbar.
  result: 'open',
  // PR14.7b/c high-value filters. Realtime contract per filter:
  //  - stageIds / teamId / valueMin / valueMax / staleDays are evaluable from a
  //    single card payload and ARE mirrored in cardMatchesFilters below.
  //  - responsibleKind (bot/none) and aiPending are server-truth only; a realtime
  //    upsert cannot be reliably classified client-side, so they force a refetch
  //    (see SERVER_ONLY_FILTER_KEYS / hasServerOnlyFilters).
  stageIds: [],
  teamId: '',
  valueMin: '',
  valueMax: '',
  staleDays: '',
  responsibleKind: '',
  aiPending: false,
});

// Filters that cannot be evaluated from a single realtime card payload. When any
// of these is active we refetch the active view on a realtime card event instead
// of trusting cardMatchesFilters (which would let a non-matching card slip in or a
// matching card drop out — the exact class of bug the old Status filter caused).
export const SERVER_ONLY_FILTER_KEYS = ['responsibleKind', 'aiPending'];

export const hasServerOnlyFilters = filters =>
  SERVER_ONLY_FILTER_KEYS.some(key => {
    const value = filters[key];
    return Array.isArray(value) ? value.length > 0 : Boolean(value);
  });

// List preferences (column visibility/order/sizing + density) are persisted in
// localStorage, namespaced per pipeline, so a user's column layout survives a
// reload. Sort/groupBy/selection are session-only (kept in store state).
const LIST_PREFS_STORAGE_KEY = 'crm_kanban_list_prefs';

const defaultListPrefs = () => ({
  columnVisibility: {},
  columnOrder: [],
  columnSizing: {},
  density: 'comfortable',
});

const listPrefsStorageKey = pipelineId =>
  `${LIST_PREFS_STORAGE_KEY}:${pipelineId || 'default'}`;

export const loadListPrefs = pipelineId => {
  try {
    const raw = window.localStorage.getItem(listPrefsStorageKey(pipelineId));
    if (!raw) return defaultListPrefs();
    return { ...defaultListPrefs(), ...JSON.parse(raw) };
  } catch (error) {
    return defaultListPrefs();
  }
};

const persistListPrefs = (pipelineId, prefs) => {
  try {
    window.localStorage.setItem(
      listPrefsStorageKey(pipelineId),
      JSON.stringify(prefs)
    );
  } catch (error) {
    // localStorage may be unavailable (private mode / quota); ignore — prefs
    // still live in store state for the session.
  }
};

export const state = {
  pipelines: [],
  board: emptyBoard(),
  cardsList: [],
  cardsListMeta: { count: 0 },
  followUps: [],
  followUpsMeta: { count: 0 },
  calendarEvents: [],
  filters: defaultFilters(),
  // List & Calendar v2 — additive view state. Sort/groupBy/selection are derived
  // over `cardsList` client-side so realtime upserts never desync (manifest R4).
  listPrefs: defaultListPrefs(),
  listSort: null, // { id:String, desc:Bool } or null
  listGroupBy: 'none', // 'none'|'stage'|'owner'
  listSelection: [], // selected card ids on the current page
  groupSummary: { group_by: null, groups: [] },
  savedViews: [],
  calendarView: 'month', // 'month'|'week'|'day'|'agenda'
  calendarRange: { from: null, to: null },
  calendarIncludeCompleted: false, // "Histórico": show done/canceled follow-ups
  calendarOverlays: { reminders: true, whatsapp: true, closeDates: true },
  calendarOwnerScope: 'all', // 'mine'|'all'
  uiFlags: {
    isFetchingPipelines: false,
    isFetchingBoard: false,
    isBootstrapping: false,
    isSavingPipeline: false,
    isArchivingPipeline: false,
    isFetchingPipelineInboxes: false,
    isSavingPipelineInbox: false,
    isRemovingPipelineInbox: false,
    isFetchingStageAutomations: false,
    isSavingStageAutomation: false,
    isDeletingStageAutomation: false,
    isFetchingInboxSettings: false,
    isSavingInboxSetting: false,
    isFetchingPipelineStages: false,
    isSavingStage: false,
    isDeletingStage: false,
    isCreatingCard: false,
    isFetchingCard: false,
    isUpdatingCard: false,
    isMovingCard: false,
    isArchivingCard: false,
    isCreatingCardFromConversation: false,
    isFetchingCardsList: false,
    isFetchingFollowUps: false,
    isSavingFollowUp: false,
    isFetchingCalendar: false,
    isBulkActing: false,
    isFetchingGroupSummary: false,
    isFetchingSavedViews: false,
    isSavingSavedView: false,
    isReschedulingFollowUp: false,
  },
};

export const getters = {
  getPipelines($state) {
    return $state.pipelines;
  },
  getBoard($state) {
    return $state.board;
  },
  getStages($state) {
    // Colunas ordenadas pela conversa mais recente (last_message_at desc,
    // epoch do payload; empate por id desc). Feito no getter, imutável, para
    // valer tanto na carga inicial quanto nos upserts realtime — o backend
    // segue paginando por id e o board reordena aqui.
    return ($state.board.stages || []).map(stage => ({
      ...stage,
      cards: [...(stage.cards || [])].sort((a, b) => {
        const bEpoch = Number(b.last_message_at) || 0;
        const aEpoch = Number(a.last_message_at) || 0;
        return bEpoch - aEpoch || (b.id || 0) - (a.id || 0);
      }),
    }));
  },
  getCardsList($state) {
    return $state.cardsList;
  },
  getCardsListMeta($state) {
    return $state.cardsListMeta;
  },
  getFollowUps($state) {
    return $state.followUps;
  },
  getFollowUpsMeta($state) {
    return $state.followUpsMeta;
  },
  getCalendarEvents($state) {
    return $state.calendarEvents;
  },
  getFilters($state) {
    return $state.filters;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getListPrefs($state) {
    return $state.listPrefs;
  },
  getListSort($state) {
    return $state.listSort;
  },
  getListGroupBy($state) {
    return $state.listGroupBy;
  },
  getListSelection($state) {
    return $state.listSelection;
  },
  getGroupSummary($state) {
    return $state.groupSummary;
  },
  getSavedViews($state) {
    return $state.savedViews;
  },
  getCalendarView($state) {
    return $state.calendarView;
  },
  getCalendarRange($state) {
    return $state.calendarRange;
  },
  getCalendarIncludeCompleted($state) {
    return $state.calendarIncludeCompleted;
  },
  getCalendarOverlays($state) {
    return $state.calendarOverlays;
  },
  getCalendarOwnerScope($state) {
    return $state.calendarOwnerScope;
  },
};

// Value range is entered in major currency units (e.g. 1500 -> R$ 1500) and the
// backend/card payload work in cents, so convert at the boundary.
const toCents = value => {
  if (value === '' || value == null) return null;
  const numeric = Number(value);
  return Number.isNaN(numeric) ? null : Math.round(numeric * 100);
};

const normalizeFilters = filters => {
  const params = {};
  if (filters.search) params.search = filters.search;
  if (filters.inboxId) params.inbox_id = filters.inboxId;
  if (filters.ownerId) params.owner_id = filters.ownerId;
  if (filters.priority) params.priority = filters.priority;
  if (filters.standalone) params.standalone = filters.standalone;
  if (filters.followUpStatus) params.follow_up_status = filters.followUpStatus;
  // List-only "Resultado" filter; the board strips it in fetchBoard.
  if (filters.result) params.result = filters.result;
  if (filters.stageIds?.length) params.stage_ids = filters.stageIds.join(',');
  if (filters.teamId) params.team_id = filters.teamId;
  // Value range is entered in major currency units; the backend stores cents.
  const valueMinCents = toCents(filters.valueMin);
  const valueMaxCents = toCents(filters.valueMax);
  if (valueMinCents != null) params.value_min = valueMinCents;
  if (valueMaxCents != null) params.value_max = valueMaxCents;
  if (filters.staleDays) params.stale_days = filters.staleDays;
  if (filters.responsibleKind)
    params.responsible_kind = filters.responsibleKind;
  if (filters.aiPending) params.ai_pending = true;
  return params;
};

const stringMatches = (value, expected) =>
  String(value || '') === String(expected || '');

// Board payload (Crm::Kanban::CardPayloadBuilder) serializes next_follow_up_at
// as epoch seconds, while realtime upserts (Crm::Cards::PayloadBuilder via the
// broadcaster) still carry the detail payload's iso8601 string. Accept both so
// the follow-up predicate stays parity-safe regardless of the card's source.
const followUpDate = value => {
  if (!value) return null;
  if (typeof value === 'number') return new Date(value * 1000);
  const numeric = Number(value);
  return Number.isNaN(numeric) ? new Date(value) : new Date(numeric * 1000);
};

// Board payload serializes last_message_at as epoch seconds; a card is stale when
// it has had no message for more than `days` (or never, i.e. null).
const isStale = (card, days) => {
  const value = card.last_message_at;
  if (!value) return true;
  const lastMessageAt =
    typeof value === 'number' ? new Date(value * 1000) : new Date(value);
  if (Number.isNaN(lastMessageAt.getTime())) return true;
  const threshold = new Date();
  threshold.setDate(threshold.getDate() - days);
  return lastMessageAt < threshold;
};

const cardMatchesFilters = (card, filters) => {
  const search = (filters.search || '').trim().toLowerCase();
  if (
    search &&
    !String(card.title || '')
      .toLowerCase()
      .includes(search)
  ) {
    return false;
  }
  if (filters.inboxId && !stringMatches(card.inbox_id, filters.inboxId)) {
    return false;
  }
  if (filters.ownerId && !stringMatches(card.owner_id, filters.ownerId)) {
    return false;
  }
  if (filters.priority && card.priority !== filters.priority) {
    return false;
  }
  // Status is intentionally NOT evaluated here: it was removed from the board
  // filters so live upserts are never silently dropped by a status mismatch.
  const followUpAt = followUpDate(card.next_follow_up_at);
  if (filters.followUpStatus === 'none' && card.next_follow_up_at) {
    return false;
  }
  if (
    filters.followUpStatus === 'pending' &&
    (!followUpAt || followUpAt < new Date())
  ) {
    return false;
  }
  if (
    filters.followUpStatus === 'overdue' &&
    (!followUpAt || followUpAt >= new Date())
  ) {
    return false;
  }
  if (filters.standalone === 'true' && !card.is_standalone) {
    return false;
  }
  if (filters.standalone === 'false' && card.is_standalone) {
    return false;
  }
  if (
    filters.stageIds?.length &&
    !filters.stageIds.some(stageId => stringMatches(card.stage_id, stageId))
  ) {
    return false;
  }
  if (filters.teamId && !stringMatches(card.team_id, filters.teamId)) {
    return false;
  }
  const valueMinCents = toCents(filters.valueMin);
  const valueMaxCents = toCents(filters.valueMax);
  if (valueMinCents != null && Number(card.value_cents || 0) < valueMinCents) {
    return false;
  }
  if (valueMaxCents != null && Number(card.value_cents || 0) > valueMaxCents) {
    return false;
  }
  if (
    Number(filters.staleDays) > 0 &&
    !isStale(card, Number(filters.staleDays))
  ) {
    return false;
  }
  // responsibleKind and aiPending are intentionally NOT evaluated here — they are
  // server-truth filters (see SERVER_ONLY_FILTER_KEYS). When active, the page
  // refetches on realtime instead of relying on this predicate.
  return true;
};

const stageTemplates = [
  { name: 'Novo', position: 1, color: '#2563eb', win_probability: 10 },
  {
    name: 'Em atendimento',
    position: 2,
    color: '#0891b2',
    win_probability: 35,
  },
  { name: 'Proposta', position: 3, color: '#ca8a04', win_probability: 65 },
  { name: 'Fechamento', position: 4, color: '#16a34a', win_probability: 90 },
  { name: 'Perdido', position: 5, color: '#dc2626', win_probability: 0 },
];

const defaultPipelinePayload = pipeline => ({
  name: pipeline?.name || 'Funil Comercial',
  description: pipeline?.description || 'Funil inicial do CRM Kanban',
  is_default: pipeline?.is_default ?? true,
  position: pipeline?.position || 1,
  ...(pipeline?.goal ? { goal: pipeline.goal } : {}),
});

const normalizeStagePayload = (stage, index) => ({
  name: stage.name,
  description: stage.description || '',
  color: stage.color || '#64748b',
  position: index + 1,
  win_probability: Number(stage.win_probability || 0),
  wip_limit: stage.wip_limit || null,
  sla_seconds: stage.sla_seconds || null,
  sla_warning_seconds: stage.sla_warning_seconds || null,
});

export const actions = {
  fetchPipelines: async ({ commit }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingPipelines: true });
    try {
      const response = await CrmKanbanAPI.getPipelines();
      commit(types.SET_CRM_KANBAN_PIPELINES, response.data.payload || []);
      return response.data.payload || [];
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingPipelines: false });
    }
  },

  fetchBoard: async ({ commit, state: $state }, payload = {}) => {
    const {
      pipelineId,
      cursorByStage = {},
      append = false,
      includeCounts = false,
      limitPerStage = 30,
      stageIds = [],
    } = payload;
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingBoard: !append });
    try {
      // The board is strictly open-only; never forward the List-only `result`
      // filter so won/lost/archived selections cannot leak into board fetches.
      const { result, ...boardFilters } = normalizeFilters($state.filters);
      // An explicit stageIds payload (used to refetch specific columns) wins;
      // otherwise keep the Stage filter's stage_ids from normalizeFilters.
      const response = await CrmKanbanAPI.getBoard({
        ...boardFilters,
        pipeline_id: pipelineId,
        cursor_by_stage: cursorByStage,
        limit_per_stage: limitPerStage,
        include_counts: includeCounts,
        ...(stageIds.length ? { stage_ids: stageIds } : {}),
      });
      const board = response.data.payload || emptyBoard();
      commit(
        append
          ? types.APPEND_CRM_KANBAN_STAGE_CARDS
          : types.SET_CRM_KANBAN_BOARD,
        board
      );
      return board;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingBoard: false });
    }
  },

  fetchCardsList: async ({ commit, state: $state }, payload = {}) => {
    const {
      pipelineId,
      page = 1,
      perPage = 50,
      sort,
      direction,
      append = false,
    } = payload;
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingCardsList: true });
    try {
      const response = await CrmKanbanAPI.getCards({
        ...normalizeFilters($state.filters),
        pipeline_id: pipelineId,
        page,
        per_page: perPage,
        // Server-side sort (FilterQuery whitelists the param). Omitted when no
        // sort is active so the default `updated_at desc` index call is unchanged.
        ...(sort ? { sort, direction: direction || 'desc' } : {}),
      });
      const fetched = response.data.payload || [];
      // `append` powers the list-view "Load more" affordance (page > 1): keep the
      // already-rendered rows and concatenate the next page instead of replacing.
      const cards = append
        ? [...($state.cardsList || []), ...fetched]
        : fetched;
      commit(types.SET_CRM_CARDS_LIST, {
        cards,
        meta: response.data.meta || { count: 0 },
      });
      return fetched;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingCardsList: false });
    }
  },

  setFilters: ({ commit }, filters) => {
    commit(types.SET_CRM_KANBAN_FILTERS, filters);
  },

  bootstrapDefaultPipeline: async ({ commit, dispatch }, payload = {}) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isBootstrapping: true });
    try {
      const response = await CrmKanbanAPI.createPipeline({
        ...defaultPipelinePayload(payload.pipeline),
      });
      const pipeline = response.data.payload;
      commit(types.ADD_CRM_KANBAN_PIPELINE, pipeline);
      await Promise.all(
        (payload.stages || stageTemplates).map((stage, index) =>
          CrmKanbanAPI.createStage(
            pipeline.id,
            normalizeStagePayload(stage, index)
          )
        )
      );
      await dispatch('fetchPipelines');
      await dispatch('fetchBoard', {
        pipelineId: pipeline.id,
        includeCounts: true,
      });
      return pipeline;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isBootstrapping: false });
    }
  },

  savePipelineWithStages: async (
    { commit, dispatch },
    { pipeline, stages }
  ) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingPipeline: true });
    try {
      const pipelinePayload = defaultPipelinePayload(pipeline);
      const response = pipeline.id
        ? await CrmKanbanAPI.updatePipeline(pipeline.id, pipelinePayload)
        : await CrmKanbanAPI.createPipeline(pipelinePayload);
      const savedPipeline = response.data.payload;
      commit(types.UPSERT_CRM_KANBAN_PIPELINE, savedPipeline);

      await Promise.all(
        stages.map((stage, index) => {
          const stagePayload = normalizeStagePayload(stage, index);
          return stage.id
            ? CrmKanbanAPI.updateStage(stage.id, stagePayload)
            : CrmKanbanAPI.createStage(savedPipeline.id, stagePayload);
        })
      );

      const savedStageIds = stages
        .filter(stage => stage.id)
        .map(stage => stage.id);
      if (savedStageIds.length > 1) {
        await CrmKanbanAPI.reorderStages(savedStageIds);
      }

      await dispatch('fetchPipelines');
      await dispatch('fetchBoard', {
        pipelineId: savedPipeline.id,
        includeCounts: true,
      });
      return savedPipeline;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingPipeline: false });
    }
  },

  archivePipeline: async ({ commit, dispatch }, pipelineId) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isArchivingPipeline: true });
    try {
      await CrmKanbanAPI.archivePipeline(pipelineId);
      commit(types.REMOVE_CRM_KANBAN_PIPELINE, pipelineId);
      const pipelines = await dispatch('fetchPipelines');
      const nextPipeline = pipelines[0];
      if (nextPipeline) {
        await dispatch('fetchBoard', {
          pipelineId: nextPipeline.id,
          includeCounts: true,
        });
      } else {
        commit(types.SET_CRM_KANBAN_BOARD, emptyBoard());
      }
      return nextPipeline || null;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isArchivingPipeline: false });
    }
  },

  fetchPipelineInboxes: async ({ commit }, pipelineId) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingPipelineInboxes: true });
    try {
      const response = await CrmKanbanAPI.getPipelineInboxes(pipelineId);
      return response.data.payload || [];
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, {
        isFetchingPipelineInboxes: false,
      });
    }
  },

  createPipelineInbox: async ({ commit }, { pipelineId, ...payload }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingPipelineInbox: true });
    try {
      const response = await CrmKanbanAPI.createPipelineInbox(
        pipelineId,
        payload
      );
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingPipelineInbox: false });
    }
  },

  deletePipelineInbox: async ({ commit }, { pipelineId, inboxId }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isRemovingPipelineInbox: true });
    try {
      await CrmKanbanAPI.deletePipelineInbox(pipelineId, inboxId);
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isRemovingPipelineInbox: false });
    }
  },

  fetchStageAutomations: async ({ commit }, stageId) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingStageAutomations: true });
    try {
      const response = await CrmKanbanAPI.getStageAutomations(stageId);
      return response.data.payload || [];
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, {
        isFetchingStageAutomations: false,
      });
    }
  },

  saveStageAutomation: async ({ commit }, { stageId, automation }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingStageAutomation: true });
    try {
      const response = automation.id
        ? await CrmKanbanAPI.updateStageAutomation(automation.id, automation)
        : await CrmKanbanAPI.createStageAutomation(stageId, automation);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingStageAutomation: false });
    }
  },

  deleteStageAutomation: async ({ commit }, automationId) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isDeletingStageAutomation: true });
    try {
      await CrmKanbanAPI.deleteStageAutomation(automationId);
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, {
        isDeletingStageAutomation: false,
      });
    }
  },

  fetchInboxSettings: async ({ commit }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingInboxSettings: true });
    try {
      const response = await CrmKanbanAPI.getInboxSettings();
      return response.data.payload || [];
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingInboxSettings: false });
    }
  },

  updateInboxSetting: async ({ commit }, { inboxId, ...payload }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingInboxSetting: true });
    try {
      const response = await CrmKanbanAPI.updateInboxSetting(inboxId, payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingInboxSetting: false });
    }
  },

  // Public booking profiles (S6) — admin only.
  fetchBookingProfiles: async () => {
    const response = await CrmKanbanAPI.getBookingProfiles();
    return response.data.payload || [];
  },

  createBookingProfile: async (_store, payload) => {
    const response = await CrmKanbanAPI.createBookingProfile(payload);
    return response.data.payload;
  },

  updateBookingProfile: async (_store, { id, ...payload }) => {
    const response = await CrmKanbanAPI.updateBookingProfile(id, payload);
    return response.data.payload;
  },

  deleteBookingProfile: async (_store, id) => {
    await CrmKanbanAPI.deleteBookingProfile(id);
  },

  fetchBookingAgentLinks: async (_store, id) => {
    const response = await CrmKanbanAPI.getBookingAgentLinks(id);
    return response.data.payload || [];
  },

  upsertBookingAgentLink: async (_store, { id, ...payload }) => {
    const response = await CrmKanbanAPI.upsertBookingAgentLink(id, payload);
    return response.data.payload;
  },

  fetchPipelineStages: async ({ commit }, pipelineId) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingPipelineStages: true });
    try {
      const response = await CrmKanbanAPI.getStages(pipelineId);
      return response.data.payload || [];
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingPipelineStages: false });
    }
  },

  deleteStage: async ({ commit }, stageId) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isDeletingStage: true });
    try {
      await CrmKanbanAPI.deleteStage(stageId);
      commit(types.REMOVE_CRM_KANBAN_STAGE, stageId);
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isDeletingStage: false });
    }
  },

  createCard: async ({ commit, dispatch }, payload) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isCreatingCard: true });
    try {
      const response = await CrmKanbanAPI.createCard(payload);
      commit(types.UPSERT_CRM_KANBAN_CARD, response.data.payload);
      await dispatch('fetchBoard', {
        pipelineId: response.data.payload.pipeline_id,
      });
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isCreatingCard: false });
    }
  },

  createCardFromConversation: async ({ commit, dispatch }, payload) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, {
      isCreatingCardFromConversation: true,
    });
    try {
      const response = await CrmKanbanAPI.createCardFromConversation(payload);
      const card = response.data.payload;
      await dispatch('handleRealtimeCardEvent', {
        event: 'crm.card.created',
        card,
      });
      return card;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, {
        isCreatingCardFromConversation: false,
      });
    }
  },

  fetchCard: async ({ commit }, id) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingCard: true });
    try {
      const response = await CrmKanbanAPI.showCard(id);
      const card = response.data.payload;
      commit(types.UPSERT_CRM_KANBAN_CARD, card);
      return card;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingCard: false });
    }
  },

  updateCard: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isUpdatingCard: true });
    try {
      const response = await CrmKanbanAPI.updateCard(id, payload);
      commit(types.UPSERT_CRM_KANBAN_CARD, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isUpdatingCard: false });
    }
  },

  archiveCard: async ({ commit }, id) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isArchivingCard: true });
    try {
      const response = await CrmKanbanAPI.archiveCard(id);
      commit(types.REMOVE_CRM_KANBAN_CARD, id);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isArchivingCard: false });
    }
  },

  closeCard: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isUpdatingCard: true });
    try {
      const response = await CrmKanbanAPI.closeCard(id, payload);
      commit(types.UPSERT_CRM_KANBAN_CARD, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isUpdatingCard: false });
    }
  },

  fetchFollowUps: async ({ commit }, payload = {}) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingFollowUps: true });
    try {
      const response = await CrmKanbanAPI.getFollowUps(payload);
      commit(types.SET_CRM_FOLLOW_UPS, {
        followUps: response.data.payload || [],
        meta: response.data.meta || { count: 0 },
      });
      return response.data.payload || [];
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingFollowUps: false });
    }
  },

  createFollowUp: async ({ commit }, payload) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: true });
    try {
      const response = await CrmKanbanAPI.createFollowUp(payload);
      commit(types.UPSERT_CRM_FOLLOW_UP, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: false });
    }
  },

  updateFollowUp: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: true });
    try {
      const response = await CrmKanbanAPI.updateFollowUp(id, payload);
      commit(types.UPSERT_CRM_FOLLOW_UP, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: false });
    }
  },

  completeFollowUp: async ({ commit }, id) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: true });
    try {
      const response = await CrmKanbanAPI.completeFollowUp(id);
      commit(types.UPSERT_CRM_FOLLOW_UP, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: false });
    }
  },

  cancelFollowUp: async ({ commit }, id) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: true });
    try {
      const response = await CrmKanbanAPI.cancelFollowUp(id);
      commit(types.UPSERT_CRM_FOLLOW_UP, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingFollowUp: false });
    }
  },

  fetchCalendarEvents: async ({ commit, state: $state }, payload = {}) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingCalendar: true });
    try {
      const response = await CrmKanbanAPI.getCalendarEvents({
        ...normalizeFilters($state.filters),
        ...payload,
      });
      commit(types.SET_CRM_CALENDAR_EVENTS, response.data.payload || []);
      return response.data.payload || [];
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingCalendar: false });
    }
  },

  moveCard: async ({ commit }, { cardId, stageId }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isMovingCard: true });
    try {
      const response = await CrmKanbanAPI.moveCard(cardId, stageId);
      commit(types.UPSERT_CRM_KANBAN_CARD, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isMovingCard: false });
    }
  },

  // --- List & Calendar v2 ---------------------------------------------------

  // Column visibility/order/sizing + density. Persisted per pipeline in
  // localStorage so the layout survives reloads; mirrored in store state for
  // the session. Pass the active pipelineId so the right namespace is written.
  setListPrefs: ({ commit }, { pipelineId, ...prefs }) => {
    commit(types.SET_CRM_LIST_PREFS, prefs);
    persistListPrefs(pipelineId, prefs);
  },

  // Hydrate prefs for the active pipeline (called on pipeline switch / mount).
  loadListPrefs: ({ commit }, pipelineId) => {
    const prefs = loadListPrefs(pipelineId);
    commit(types.SET_CRM_LIST_PREFS, prefs);
    return prefs;
  },

  setListSort: ({ commit }, sort) => {
    commit(types.SET_CRM_LIST_SORT, sort || null);
  },

  setListGroupBy: ({ commit }, groupBy) => {
    commit(types.SET_CRM_LIST_GROUP_BY, groupBy || 'none');
  },

  setListSelection: ({ commit }, ids) => {
    commit(types.SET_CRM_LIST_SELECTION, Array.isArray(ids) ? ids : []);
  },

  // Bulk move/assign/status/delete. Returns { updated, failed } so the page can
  // toast partial results. `action` is the manifest verb; the API layer remaps
  // it to `action_name` (Rails reserves `action` as a routing param).
  bulkAction: async ({ commit, dispatch }, { ids, action, payload = {} }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isBulkActing: true });
    try {
      const response = await CrmKanbanAPI.bulkAction({ ids, action, payload });
      const result = response.data.payload || { updated: [], failed: [] };
      // Re-sync the mutated cards from server truth. Realtime broadcasts also
      // fire per card (see BulkAction service), but refetching keeps the list
      // authoritative when realtime is racing or filtered out.
      const updatedIds = result.updated || [];
      if (action === 'delete') {
        updatedIds.forEach(id => commit(types.REMOVE_CRM_CARD_FROM_LIST, id));
      }
      // Clear selection of cards that were successfully acted on.
      if (updatedIds.length) {
        await dispatch(
          'setListSelection',
          (ids || []).filter(id => !updatedIds.includes(id))
        );
      }
      return result;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isBulkActing: false });
    }
  },

  fetchGroupSummary: async (
    { commit, state: $state },
    { pipelineId, groupBy } = {}
  ) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingGroupSummary: true });
    try {
      const response = await CrmKanbanAPI.cardsGroupSummary({
        ...normalizeFilters($state.filters),
        pipeline_id: pipelineId,
        group_by: groupBy,
      });
      const summary = response.data.payload || { group_by: null, groups: [] };
      commit(types.SET_CRM_GROUP_SUMMARY, summary);
      return summary;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingGroupSummary: false });
    }
  },

  fetchSavedViews: async ({ commit }, pipelineId) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingSavedViews: true });
    try {
      const response = await CrmKanbanAPI.getSavedViews({
        pipeline_id: pipelineId,
      });
      const views = response.data.payload || [];
      commit(types.SET_CRM_SAVED_VIEWS, views);
      return views;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isFetchingSavedViews: false });
    }
  },

  saveSavedView: async ({ commit }, payload) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingSavedView: true });
    try {
      const response = payload.id
        ? await CrmKanbanAPI.updateSavedView(payload.id, payload)
        : await CrmKanbanAPI.createSavedView(payload);
      const view = response.data.payload;
      commit(types.UPSERT_CRM_SAVED_VIEW, view);
      return view;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingSavedView: false });
    }
  },

  deleteSavedView: async ({ commit }, id) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingSavedView: true });
    try {
      await CrmKanbanAPI.deleteSavedView(id);
      commit(types.REMOVE_CRM_SAVED_VIEW, id);
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isSavingSavedView: false });
    }
  },

  setCalendarView: ({ commit }, view) => {
    commit(types.SET_CRM_CALENDAR_VIEW, view || 'month');
  },

  setCalendarRange: ({ commit }, range) => {
    commit(types.SET_CRM_CALENDAR_RANGE, range || { from: null, to: null });
  },

  setCalendarIncludeCompleted: ({ commit }, value) => {
    commit(types.SET_CRM_CALENDAR_INCLUDE_COMPLETED, value === true);
  },

  setCalendarOverlays: ({ commit }, overlays) => {
    commit(types.SET_CRM_CALENDAR_OVERLAYS, overlays);
  },

  setCalendarOwnerScope: ({ commit }, scope) => {
    commit(types.SET_CRM_CALENDAR_OWNER_SCOPE, scope || 'all');
  },

  // Intent-named follow-up reschedule. Thin wrapper over the reschedule
  // endpoint (past-guard for WhatsApp lives server-side in Rescheduler). The
  // returned follow-up carries its parent card; realtime keeps the list/board
  // in sync, so we only upsert the follow-up here.
  rescheduleFollowUp: async ({ commit }, { id, dueAt }) => {
    commit(types.SET_CRM_KANBAN_UI_FLAG, { isReschedulingFollowUp: true });
    try {
      const response = await CrmKanbanAPI.rescheduleFollowUp(id, dueAt);
      commit(types.UPSERT_CRM_FOLLOW_UP, response.data.payload);
      return response.data.payload;
    } finally {
      commit(types.SET_CRM_KANBAN_UI_FLAG, { isReschedulingFollowUp: false });
    }
  },

  // Inline card-field update with optimistic display + rollback. Routes each
  // field to the correct existing path: value_cents/owner_id/expected_close_at
  // → PATCH updateCard (value edit auto-locks value_source server-side, R6);
  // stage_id → moveCard; status won/lost → closeCard. The component dispatches
  // this with { id, <field>: <value> }. On API failure the previous card row is
  // restored so the table never shows a value the server rejected (R5/R6).
  updateCardFields: async (
    { commit, dispatch, state: $state },
    { id, ...fields }
  ) => {
    const previous = ($state.cardsList || []).find(card => card.id === id);

    // Stage change goes through the dedicated move endpoint.
    if (fields.stage_id != null) {
      return dispatch('moveCard', { cardId: id, stageId: fields.stage_id });
    }

    // Won/lost route to the close path (status is NOT a permitted PATCH field).
    if (fields.status === 'won' || fields.status === 'lost') {
      return dispatch('closeCard', { id, result: fields.status, ...fields });
    }

    // Optimistic patch of the list row for the permitted PATCH fields.
    if (previous) {
      commit(types.UPSERT_CRM_CARD_IN_LIST, { ...previous, ...fields });
    }
    try {
      return await dispatch('updateCard', { id, ...fields });
    } catch (error) {
      // Roll back to the pre-edit row so the table reflects server truth.
      if (previous) commit(types.UPSERT_CRM_CARD_IN_LIST, previous);
      throw error;
    }
  },

  handleRealtimeCardEvent: ({ commit, state: $state }, { event, card }) => {
    if (!card?.id || !$state.board.pipeline?.id) return;

    const isSamePipeline = stringMatches(
      card.pipeline_id,
      $state.board.pipeline.id
    );
    const isArchived =
      event === 'crm.card.archived' || card.status === 'archived';

    // Status transitions (won/lost/reopen) are invisible to cardMatchesFilters,
    // which intentionally never evaluates status. Two collections care about it:
    // the Kanban board is strictly open-only (server scope `.open`), so any
    // non-open status leaves it; the List honors `filters.result`, so a status
    // that mismatches an active result filter leaves it. Either way, defer to
    // server truth (refetch the active view) instead of optimistically keeping a
    // stale row. Guarded on a present status so normal stage moves still upsert.
    // (Archived keeps its dedicated removal branch below.)
    const statusLeavesView =
      card.status != null &&
      !isArchived &&
      (!stringMatches(card.status, 'open') ||
        (Boolean($state.filters.result) &&
          !stringMatches(card.status, $state.filters.result)));

    // Server-only filters cannot be evaluated from this single card payload, so
    // trusting cardMatchesFilters would reintroduce the status-style realtime bug.
    // Defer to server truth: refetch the active view (the page handles the event).
    if (
      isSamePipeline &&
      !isArchived &&
      (statusLeavesView || hasServerOnlyFilters($state.filters))
    ) {
      emitter.emit(BUS_EVENTS.CRM_BOARD_REFETCH);
      return;
    }

    if (
      !isSamePipeline ||
      isArchived ||
      !cardMatchesFilters(card, $state.filters)
    ) {
      commit(types.REMOVE_CRM_KANBAN_CARD, card.id);
      commit(types.REMOVE_CRM_CARD_FROM_LIST, card.id);
      return;
    }

    commit(types.UPSERT_CRM_KANBAN_CARD, card);
    commit(types.UPSERT_CRM_CARD_IN_LIST, card);
  },
};

const upsertCardInStages = (stages, card) =>
  stages.map(stage => {
    const cards = stage.cards || [];
    const existingIndex = cards.findIndex(item => item.id === card.id);
    if (stage.id !== card.stage_id) {
      return {
        ...stage,
        cards: cards.filter(item => item.id !== card.id),
      };
    }

    if (existingIndex === -1) return { ...stage, cards: [card, ...cards] };

    return {
      ...stage,
      cards: cards.map(item => (item.id === card.id ? card : item)),
    };
  });

const upsertItem = (items, item) => {
  const existingIndex = items.findIndex(existing => existing.id === item.id);
  if (existingIndex === -1) return [item, ...items];
  return items.map(existing => (existing.id === item.id ? item : existing));
};

export const mutations = {
  [types.SET_CRM_KANBAN_UI_FLAG]($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
  [types.SET_CRM_KANBAN_PIPELINES]($state, pipelines) {
    $state.pipelines = pipelines;
  },
  [types.ADD_CRM_KANBAN_PIPELINE]($state, pipeline) {
    $state.pipelines = [pipeline, ...$state.pipelines];
  },
  [types.UPSERT_CRM_KANBAN_PIPELINE]($state, pipeline) {
    const existingIndex = $state.pipelines.findIndex(
      item => item.id === pipeline.id
    );
    if (existingIndex === -1) {
      $state.pipelines = [pipeline, ...$state.pipelines];
      return;
    }
    $state.pipelines = $state.pipelines.map(item =>
      item.id === pipeline.id ? pipeline : item
    );
    if ($state.board.pipeline?.id === pipeline.id) {
      $state.board = { ...$state.board, pipeline };
    }
  },
  [types.REMOVE_CRM_KANBAN_PIPELINE]($state, pipelineId) {
    $state.pipelines = $state.pipelines.filter(
      pipeline => pipeline.id !== pipelineId
    );
    if ($state.board.pipeline?.id === pipelineId) {
      $state.board = emptyBoard();
    }
  },
  [types.SET_CRM_KANBAN_BOARD]($state, board) {
    $state.board = board || emptyBoard();
  },
  [types.APPEND_CRM_KANBAN_STAGE_CARDS]($state, board) {
    const incomingStages = board.stages || [];
    $state.board = {
      ...$state.board,
      stages: ($state.board.stages || []).map(stage => {
        const incoming = incomingStages.find(item => item.id === stage.id);
        if (!incoming) return stage;
        return {
          ...stage,
          cards: [...(stage.cards || []), ...(incoming.cards || [])].filter(
            (card, index, cards) =>
              cards.findIndex(item => item.id === card.id) === index
          ),
          has_more: incoming.has_more,
          next_cursor: incoming.next_cursor,
        };
      }),
    };
  },
  [types.SET_CRM_KANBAN_FILTERS]($state, filters) {
    $state.filters = { ...$state.filters, ...filters };
  },
  [types.SET_CRM_CARDS_LIST]($state, { cards, meta }) {
    $state.cardsList = cards || [];
    $state.cardsListMeta = meta || { count: 0 };
  },
  [types.UPSERT_CRM_CARD_IN_LIST]($state, card) {
    $state.cardsList = upsertItem($state.cardsList || [], card);
  },
  [types.REMOVE_CRM_CARD_FROM_LIST]($state, cardId) {
    $state.cardsList = ($state.cardsList || []).filter(
      card => card.id !== cardId
    );
  },
  [types.SET_CRM_FOLLOW_UPS]($state, { followUps, meta }) {
    $state.followUps = followUps || [];
    $state.followUpsMeta = meta || { count: 0 };
  },
  [types.UPSERT_CRM_FOLLOW_UP]($state, followUp) {
    $state.followUps = upsertItem($state.followUps || [], followUp);
  },
  [types.REMOVE_CRM_FOLLOW_UP]($state, followUpId) {
    $state.followUps = ($state.followUps || []).filter(
      followUp => followUp.id !== followUpId
    );
  },
  [types.SET_CRM_CALENDAR_EVENTS]($state, events) {
    $state.calendarEvents = events || [];
  },
  [types.SET_CRM_LIST_PREFS]($state, prefs) {
    $state.listPrefs = { ...$state.listPrefs, ...prefs };
  },
  [types.SET_CRM_LIST_SORT]($state, sort) {
    $state.listSort = sort;
  },
  [types.SET_CRM_LIST_GROUP_BY]($state, groupBy) {
    $state.listGroupBy = groupBy;
  },
  [types.SET_CRM_LIST_SELECTION]($state, ids) {
    $state.listSelection = ids || [];
  },
  [types.SET_CRM_GROUP_SUMMARY]($state, summary) {
    $state.groupSummary = summary || { group_by: null, groups: [] };
  },
  [types.SET_CRM_SAVED_VIEWS]($state, views) {
    $state.savedViews = views || [];
  },
  [types.UPSERT_CRM_SAVED_VIEW]($state, view) {
    $state.savedViews = upsertItem($state.savedViews || [], view);
  },
  [types.REMOVE_CRM_SAVED_VIEW]($state, id) {
    $state.savedViews = ($state.savedViews || []).filter(
      view => view.id !== id
    );
  },
  [types.SET_CRM_CALENDAR_VIEW]($state, view) {
    $state.calendarView = view;
  },
  [types.SET_CRM_CALENDAR_RANGE]($state, range) {
    $state.calendarRange = range || { from: null, to: null };
  },
  [types.SET_CRM_CALENDAR_INCLUDE_COMPLETED]($state, value) {
    $state.calendarIncludeCompleted = value === true;
  },
  [types.SET_CRM_CALENDAR_OVERLAYS]($state, overlays) {
    $state.calendarOverlays = { ...$state.calendarOverlays, ...overlays };
  },
  [types.SET_CRM_CALENDAR_OWNER_SCOPE]($state, scope) {
    $state.calendarOwnerScope = scope;
  },
  [types.RESTORE_CRM_KANBAN_STAGES]($state, stages) {
    $state.board = { ...$state.board, stages };
  },
  [types.UPSERT_CRM_KANBAN_STAGE]($state, stage) {
    const stages = $state.board.stages || [];
    const existingIndex = stages.findIndex(item => item.id === stage.id);
    if (existingIndex === -1) {
      $state.board = { ...$state.board, stages: [...stages, stage] };
      return;
    }
    $state.board = {
      ...$state.board,
      stages: stages.map(item => (item.id === stage.id ? stage : item)),
    };
  },
  [types.REMOVE_CRM_KANBAN_STAGE]($state, stageId) {
    $state.board = {
      ...$state.board,
      stages: ($state.board.stages || []).filter(stage => stage.id !== stageId),
    };
  },
  [types.UPSERT_CRM_KANBAN_CARD]($state, card) {
    $state.board = {
      ...$state.board,
      stages: upsertCardInStages($state.board.stages || [], card),
    };
  },
  [types.REMOVE_CRM_KANBAN_CARD]($state, cardId) {
    $state.board = {
      ...$state.board,
      stages: ($state.board.stages || []).map(stage => ({
        ...stage,
        cards: (stage.cards || []).filter(card => card.id !== cardId),
      })),
    };
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
