<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useEmitter } from 'dashboard/composables/emitter';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { defaultFilters } from 'dashboard/store/modules/crmKanban';
import { useCrmPermissions } from '../composables/useCrmPermissions';
import crmMeetingsAPI from 'dashboard/api/crmMeetings';
import CtwaCampaignsAPI from 'dashboard/api/ctwaCampaigns';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import Draggable from 'vuedraggable';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConfirmModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';
import CrmKanbanCard from '../components/CrmKanbanCard.vue';
import CrmCardDrawer from '../components/CrmCardDrawer.vue';
import CrmPipelineDrawer from '../components/CrmPipelineDrawer.vue';
import CrmInboxSettingsDrawer from '../components/CrmInboxSettingsDrawer.vue';
import CrmBookingProfilesDrawer from '../components/CrmBookingProfilesDrawer.vue';
import CrmCardsTable from '../components/list/CrmCardsTable.vue';
import CrmTableColumnSettings from '../components/list/CrmTableColumnSettings.vue';
import CrmSavedViews from '../components/list/CrmSavedViews.vue';
import CrmResultTabs from '../components/list/CrmResultTabs.vue';
import CrmBulkActionBar from '../components/list/CrmBulkActionBar.vue';
import CrmCalendar from '../components/calendar/CrmCalendar.vue';
import CrmCalendarQuickAdd from '../components/calendar/CrmCalendarQuickAdd.vue';
import CrmCalendarMeetingScheduler from '../components/calendar/CrmCalendarMeetingScheduler.vue';
import CrmMeetingDetail from '../components/calendar/CrmMeetingDetail.vue';
import {
  buildCrmCardColumns,
  DEFAULT_COLUMN_ORDER,
  DEFAULT_COLUMN_VISIBILITY,
  COLUMN_TO_SORT_PARAM,
} from '../components/list/cardColumns.js';

const store = useStore();
const { t } = useI18n();

const pipelines = useMapGetter('crmKanban/getPipelines');
const stages = useMapGetter('crmKanban/getStages');
const cardsList = useMapGetter('crmKanban/getCardsList');
const cardsListMeta = useMapGetter('crmKanban/getCardsListMeta');
const followUps = useMapGetter('crmKanban/getFollowUps');
const calendarEvents = useMapGetter('crmKanban/getCalendarEvents');
const uiFlags = useMapGetter('crmKanban/getUIFlags');
const storedFilters = useMapGetter('crmKanban/getFilters');
const listPrefs = useMapGetter('crmKanban/getListPrefs');
const listSort = useMapGetter('crmKanban/getListSort');
const listGroupBy = useMapGetter('crmKanban/getListGroupBy');
const listSelection = useMapGetter('crmKanban/getListSelection');
const savedViews = useMapGetter('crmKanban/getSavedViews');
const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');
const inboxes = useMapGetter('inboxes/getInboxes');
const agents = useMapGetter('agents/getAgents');
const teams = useMapGetter('teams/getTeams');
const accountLabels = useMapGetter('labels/getLabels');
const { canManageCards, canMoveCards, canManagePipelines, canManageAi } =
  useCrmPermissions();

const CRM_CALENDAR_MEETINGS_FEATURE = 'CRM_CALENDAR_MEETINGS_ENABLED';
const isCrmAiEnabled = computed(
  () =>
    store.getters['globalConfig/get']?.crmAiEnabled === true ||
    window.globalConfig?.CRM_AI_ENABLED === 'true'
);

const route = useRoute();
const router = useRouter();
// Calendar-only sub-page (route meta.calendarOnly): opens straight on the calendar
// with the kanban/list/calendar switch and "New pipeline" button hidden.
const isCalendarOnly = computed(() => route.meta?.calendarOnly === true);

const currentPipelineId = ref('');
const viewMode = ref(isCalendarOnly.value ? 'calendar' : 'kanban');
// The two CRM routes share this component, so the instance is reused on navigation:
// keep viewMode in sync with the route (force calendar on the calendar-only page).
watch(isCalendarOnly, only => {
  viewMode.value = only ? 'calendar' : 'kanban';
});
const filters = ref({ ...storedFilters.value });
const drawerMode = ref('create');
const selectedCard = ref(null);
const showDrawer = ref(false);
// Which tab the card drawer lands on when opened ('followups' from the calendar
// quick-add "Continuar"; null → default summary).
const drawerInitialTab = ref(null);
const openedRouteCardId = ref(null);
const pipelineDrawerMode = ref('create');
const showPipelineDrawer = ref(false);
const pipelineInboxes = ref([]);
const showInboxSettingsDrawer = ref(false);
const showBookingProfilesDrawer = ref(false);
const inboxSettings = ref([]);
const inboxSettingStagesByPipeline = ref({});
const dragSnapshot = ref(null);
const loadError = ref('');
const confirmModal = ref(null);
const confirmConfig = ref({
  title: '',
  description: '',
  confirmLabel: '',
});

const isLoading = computed(
  () => uiFlags.value.isFetchingPipelines || uiFlags.value.isFetchingBoard
);
const hasPipelines = computed(() => pipelines.value.length > 0);
const hasBoardContent = computed(() => stages.value.length > 0);
const selectedPipeline = computed(() =>
  pipelines.value.find(
    pipeline => pipeline.id === Number(currentPipelineId.value)
  )
);

const pipelineOptions = computed(() =>
  pipelines.value.map(pipeline => ({
    value: pipeline.id,
    label: pipeline.name,
  }))
);
const inboxOptions = computed(() =>
  inboxes.value.map(inbox => ({ value: inbox.id, label: inbox.name }))
);
const agentOptions = computed(() =>
  agents.value.map(agent => ({ value: agent.id, label: agent.name }))
);
const priorityOptions = computed(() => [
  { value: 'low', label: t('CRM_KANBAN.PRIORITY.LOW') },
  { value: 'medium', label: t('CRM_KANBAN.PRIORITY.MEDIUM') },
  { value: 'high', label: t('CRM_KANBAN.PRIORITY.HIGH') },
  { value: 'urgent', label: t('CRM_KANBAN.PRIORITY.URGENT') },
]);
const followUpStatusOptions = computed(() => [
  { value: 'none', label: t('CRM_KANBAN.FOLLOW_UP_FILTER.NONE') },
  { value: 'pending', label: t('CRM_KANBAN.FOLLOW_UP_FILTER.PENDING') },
  { value: 'overdue', label: t('CRM_KANBAN.FOLLOW_UP_FILTER.OVERDUE') },
]);
// List-view-only "Resultado" filter (won/lost/archived). The board stays
// open-only, so this control is rendered only when viewMode === 'list'.
const resultOptions = computed(() => [
  { value: 'open', label: t('CRM_KANBAN.RESULT_FILTER.OPEN') },
  { value: 'won', label: t('CRM_KANBAN.RESULT_FILTER.WON') },
  { value: 'lost', label: t('CRM_KANBAN.RESULT_FILTER.LOST') },
  { value: 'archived', label: t('CRM_KANBAN.RESULT_FILTER.ARCHIVED') },
]);
const teamOptions = computed(() =>
  teams.value.map(team => ({ value: team.id, label: team.name }))
);
const stageOptions = computed(() =>
  stages.value.map(stage => ({ value: stage.id, label: stage.name }))
);
const responsibleOptions = computed(() => [
  { value: 'agent', label: t('CRM_KANBAN.RESPONSIBLE_FILTER.AGENT') },
  { value: 'bot', label: t('CRM_KANBAN.RESPONSIBLE_FILTER.BOT') },
  { value: 'none', label: t('CRM_KANBAN.RESPONSIBLE_FILTER.NONE') },
]);
const staleOptions = computed(() => [
  { value: '3', label: t('CRM_KANBAN.STALE_FILTER.THREE_DAYS') },
  { value: '7', label: t('CRM_KANBAN.STALE_FILTER.SEVEN_DAYS') },
  { value: '14', label: t('CRM_KANBAN.STALE_FILTER.FOURTEEN_DAYS') },
  { value: '30', label: t('CRM_KANBAN.STALE_FILTER.THIRTY_DAYS') },
]);
const linkedOptions = computed(() => [
  { value: 'false', label: t('CRM_KANBAN.LINKED_FILTER.LINKED') },
  { value: 'true', label: t('CRM_KANBAN.LINKED_FILTER.STANDALONE') },
]);
const labelOptions = computed(() =>
  accountLabels.value.map(label => ({
    value: label.id,
    label: label.title,
    color: label.color,
  }))
);
// Opções de campanha CTWA (headline + nº de conversas por anúncio), carregadas
// do endpoint único /ctwa_campaigns. `value` fica String — source_id de anúncio
// Meta estoura Number.MAX_SAFE_INTEGER, então nada de coerção numérica.
const campaignOptions = ref([]);
const campaignFilterOptions = computed(() =>
  campaignOptions.value.map(option => ({
    value: String(option.source_id),
    label: option.headline || String(option.source_id),
    count: option.count,
  }))
);

const loadCampaignOptions = async () => {
  try {
    const response = await CtwaCampaignsAPI.get();
    campaignOptions.value = response.data.payload || [];
  } catch {
    // Sem opções o grupo mostra só o placeholder; não bloqueia o board.
    campaignOptions.value = [];
  }
};

const filtersPopover = ref(null);

// Toggle a stage id in the multi-select stage filter.
const toggleStageFilter = stageId => {
  const current = filters.value.stageIds || [];
  filters.value.stageIds = current.some(id => Number(id) === Number(stageId))
    ? current.filter(id => Number(id) !== Number(stageId))
    : [...current, stageId];
};

const isStageSelected = stageId =>
  (filters.value.stageIds || []).some(id => Number(id) === Number(stageId));

// Toggle a label id in the multi-select label filter (same Number-compare
// contract as stages: label ids are plain integers).
const toggleLabelFilter = labelId => {
  const current = filters.value.labelIds || [];
  filters.value.labelIds = current.some(id => Number(id) === Number(labelId))
    ? current.filter(id => Number(id) !== Number(labelId))
    : [...current, labelId];
};

const isLabelSelected = labelId =>
  (filters.value.labelIds || []).some(id => Number(id) === Number(labelId));

// Toggle de campanha por source_id — comparação SEMPRE por String (ids Meta
// não cabem em Number com segurança).
const toggleCampaignFilter = sourceId => {
  const current = filters.value.campaignSourceIds || [];
  filters.value.campaignSourceIds = current.some(
    id => String(id) === String(sourceId)
  )
    ? current.filter(id => String(id) !== String(sourceId))
    : [...current, String(sourceId)];
};

const isCampaignSelected = sourceId =>
  (filters.value.campaignSourceIds || []).some(
    id => String(id) === String(sourceId)
  );

const labelForOption = (options, value) =>
  options.value.find(option => String(option.value) === String(value))?.label ||
  String(value);

// Active-filter chips shown in the toolbar. Each chip knows how to clear itself.
const activeFilterChips = computed(() => {
  const chips = [];
  const f = filters.value;
  if (f.search) {
    chips.push({
      key: 'search',
      label: `${t('CRM_KANBAN.FILTERS.SEARCH')}: ${f.search}`,
    });
  }
  if (f.inboxId) {
    chips.push({
      key: 'inboxId',
      label: `${t('CRM_KANBAN.FILTERS.INBOX')}: ${labelForOption(inboxOptions, f.inboxId)}`,
    });
  }
  if (f.ownerId) {
    chips.push({
      key: 'ownerId',
      label: `${t('CRM_KANBAN.FILTERS.OWNER')}: ${labelForOption(agentOptions, f.ownerId)}`,
    });
  }
  if (f.priority) {
    chips.push({
      key: 'priority',
      label: `${t('CRM_KANBAN.FILTERS.PRIORITY')}: ${labelForOption(priorityOptions, f.priority)}`,
    });
  }
  if (f.followUpStatus) {
    chips.push({
      key: 'followUpStatus',
      label: `${t('CRM_KANBAN.FILTERS.FOLLOW_UP')}: ${labelForOption(followUpStatusOptions, f.followUpStatus)}`,
    });
  }
  // 'open' is the default result (the "Em andamento" tab), so it is not a real
  // active filter. Any other value — won/lost/archived OR '' ("Todos") — IS a
  // deviation, so it must chip and be clearable; otherwise picking "Todos" in the
  // popover would strand the list in a state the toolbar can't reset.
  if (f.result !== 'open' && viewMode.value === 'list') {
    // '' is the "Todos" (all statuses) option, which isn't in resultOptions.
    const resultLabel =
      f.result === ''
        ? t('CRM_KANBAN.FILTERS.ALL')
        : labelForOption(resultOptions, f.result);
    chips.push({
      key: 'result',
      label: `${t('CRM_KANBAN.FILTERS.RESULT')}: ${resultLabel}`,
    });
  }
  if (f.stageIds?.length) {
    const names = f.stageIds
      .map(id => labelForOption(stageOptions, id))
      .join(', ');
    chips.push({
      key: 'stageIds',
      label: `${t('CRM_KANBAN.FILTERS.STAGE')}: ${names}`,
    });
  }
  if (f.labelIds?.length) {
    const names = f.labelIds
      .map(id => labelForOption(labelOptions, id))
      .join(', ');
    chips.push({
      key: 'labelIds',
      label: `${t('CRM_KANBAN.FILTERS.LABELS')}: ${names}`,
    });
  }
  if (f.campaignSourceIds?.length) {
    // labelForOption cai para o próprio source_id quando a option não carrega
    // headline (mesmo fallback do multi-select).
    const names = f.campaignSourceIds
      .map(id => labelForOption(campaignFilterOptions, id))
      .join(', ');
    chips.push({
      key: 'campaignSourceIds',
      label: `${t('CRM_KANBAN.FILTERS.CAMPAIGN')}: ${names}`,
    });
  }
  if (f.teamId) {
    chips.push({
      key: 'teamId',
      label: `${t('CRM_KANBAN.FILTERS.TEAM')}: ${labelForOption(teamOptions, f.teamId)}`,
    });
  }
  if (f.responsibleKind) {
    chips.push({
      key: 'responsibleKind',
      label: `${t('CRM_KANBAN.FILTERS.RESPONSIBLE')}: ${labelForOption(responsibleOptions, f.responsibleKind)}`,
    });
  }
  if (f.valueMin !== '' || f.valueMax !== '') {
    const min = f.valueMin === '' ? '…' : f.valueMin;
    const max = f.valueMax === '' ? '…' : f.valueMax;
    chips.push({
      key: 'value',
      label: `${t('CRM_KANBAN.FILTERS.VALUE_RANGE')}: ${min} – ${max}`,
    });
  }
  if (f.staleDays) {
    chips.push({
      key: 'staleDays',
      label: `${t('CRM_KANBAN.FILTERS.STALE')}: ${labelForOption(staleOptions, f.staleDays)}`,
    });
  }
  if (f.standalone) {
    chips.push({
      key: 'standalone',
      label: `${t('CRM_KANBAN.FILTERS.LINKED')}: ${labelForOption(linkedOptions, f.standalone)}`,
    });
  }
  if (f.aiPending) {
    chips.push({ key: 'aiPending', label: t('CRM_KANBAN.FILTERS.AI_PENDING') });
  }
  return chips;
});

const activeFilterCount = computed(() => activeFilterChips.value.length);

const viewModeOptions = computed(() => [
  {
    id: 'kanban',
    label: t('CRM_KANBAN.VIEWS.KANBAN'),
    icon: 'i-lucide-kanban',
  },
  { id: 'list', label: t('CRM_KANBAN.VIEWS.LIST'), icon: 'i-lucide-list' },
  {
    id: 'calendar',
    label: t('CRM_KANBAN.VIEWS.CALENDAR'),
    icon: 'i-lucide-calendar-days',
  },
]);

const fetchBoard = (includeCounts = false) => {
  if (!currentPipelineId.value) return Promise.resolve();
  return store.dispatch('crmKanban/fetchBoard', {
    pipelineId: currentPipelineId.value,
    includeCounts,
  });
};

const loadCurrentBoard = async (includeCounts = false) => {
  loadError.value = '';
  try {
    await fetchBoard(includeCounts);
  } catch {
    loadError.value = t('CRM_KANBAN.ERRORS.LOAD');
    useAlert(t('CRM_KANBAN.ERRORS.LOAD'));
  }
};

const calendarRange = () => {
  const now = new Date();
  const from = new Date(now);
  from.setDate(now.getDate() - 30);
  const to = new Date(now);
  to.setDate(now.getDate() + 90);
  return {
    from: from.toISOString(),
    to: to.toISOString(),
  };
};

// List pagination: page 1 replaces the list; "Load more" bumps the page and
// appends. has-more is derived from loaded rows vs the server total count.
const listPage = ref(1);
const listPageSize = 75;
const hasMoreCards = computed(
  () => cardsList.value.length < (cardsListMeta.value?.count || 0)
);

const loadCurrentList = async ({ append = false } = {}) => {
  if (!currentPipelineId.value) return;
  loadError.value = '';
  if (!append) listPage.value = 1;
  // Map the table's column id (e.g. `value`) to the backend sort param the
  // FilterQuery whitelists (e.g. `value_cents`). Omitted when no sort is active.
  const activeSort = listSort.value;
  const sortParam = activeSort?.id
    ? COLUMN_TO_SORT_PARAM[activeSort.id]
    : undefined;
  try {
    await store.dispatch('crmKanban/fetchCardsList', {
      pipelineId: currentPipelineId.value,
      page: listPage.value,
      perPage: listPageSize,
      append,
      ...(sortParam
        ? { sort: sortParam, direction: activeSort.desc ? 'desc' : 'asc' }
        : {}),
    });
  } catch {
    loadError.value = t('CRM_KANBAN.ERRORS.LOAD');
    useAlert(t('CRM_KANBAN.ERRORS.LOAD'));
  }
};

// "Load more" in list view: advance the page and append the next slice.
const loadMoreList = async () => {
  if (!hasMoreCards.value || uiFlags.value.isFetchingCardsList) return;
  listPage.value += 1;
  await loadCurrentList({ append: true });
};

const loadCurrentCalendar = async () => {
  if (!currentPipelineId.value) return;
  loadError.value = '';
  // The calendar emits range-change with the visible window; use that when
  // present, else the legacy ±30/90d default for the very first fetch.
  const storedRange = store.getters['crmKanban/getCalendarRange'];
  const range =
    storedRange?.from && storedRange?.to
      ? { from: storedRange.from, to: storedRange.to }
      : calendarRange();
  try {
    // Owner scope (mine/all) is applied client-side by the orchestrator via
    // filterByOwner, so the fetch always pulls the full pipeline window.
    // Completed/canceled follow-ups are hidden unless the "Histórico" toggle is on.
    await store.dispatch('crmKanban/fetchCalendarEvents', {
      pipeline_id: currentPipelineId.value,
      include_completed: store.getters['crmKanban/getCalendarIncludeCompleted'],
      ...range,
    });
  } catch {
    loadError.value = t('CRM_KANBAN.ERRORS.LOAD');
    useAlert(t('CRM_KANBAN.ERRORS.LOAD'));
  }
};

const loadActiveView = async (includeCounts = false) => {
  if (viewMode.value === 'list') return loadCurrentList();
  if (viewMode.value === 'calendar') return loadCurrentCalendar();
  return loadCurrentBoard(includeCounts);
};

const handleRealtimeConnected = async () => {
  await loadCurrentBoard(true);
};

// Server-only filters (responsible=bot/none, AI-pending) cannot be evaluated from a
// single realtime card payload, so the store asks us to refetch active view instead.
// Debounce so a burst of realtime events triggers a single reload.
let refetchTimer = null;
const handleServerFilterRefetch = () => {
  if (refetchTimer) clearTimeout(refetchTimer);
  refetchTimer = setTimeout(() => loadActiveView(true), 400);
};

const refreshData = async () => {
  loadError.value = '';
  try {
    await Promise.allSettled([
      store.dispatch('inboxes/get'),
      store.dispatch('agents/get'),
      store.dispatch('teams/get'),
      // Labels hidratam as opções do filtro de etiquetas e as cores dos cards
      // (deep-link direto no CRM não passa pela sidebar, que normalmente carrega).
      store.dispatch('labels/get'),
      loadCampaignOptions(),
    ]);
    const fetchedPipelines = await store.dispatch('crmKanban/fetchPipelines');
    if (fetchedPipelines.length > 0) {
      const currentStillExists = fetchedPipelines.some(
        pipeline => String(pipeline.id) === String(currentPipelineId.value)
      );
      const nextPipelineId = currentStillExists
        ? currentPipelineId.value
        : fetchedPipelines[0].id;
      if (String(currentPipelineId.value) === String(nextPipelineId)) {
        await loadActiveView(true);
        return;
      }
      currentPipelineId.value = nextPipelineId;
    }
  } catch {
    loadError.value = t('CRM_KANBAN.ERRORS.LOAD');
    useAlert(t('CRM_KANBAN.ERRORS.LOAD'));
  }
};

const applyFilters = async () => {
  loadError.value = '';
  try {
    await store.dispatch('crmKanban/setFilters', filters.value);
    await loadActiveView(true);
  } catch {
    loadError.value = t('CRM_KANBAN.ERRORS.FILTER');
    useAlert(t('CRM_KANBAN.ERRORS.FILTER'));
  }
};

const clearFilters = async () => {
  filters.value = defaultFilters();
  await applyFilters();
};

// List status tabs (open/won/lost). Writes the same `filters.result` the Filtros
// popover uses, so the tabs and the popover stay in sync.
const selectResult = async value => {
  filters.value.result = value;
  await applyFilters();
};

const applyFiltersFromPopover = async () => {
  filtersPopover.value?.hide();
  await applyFilters();
};

const removeFilterChip = async key => {
  const defaults = defaultFilters();
  if (key === 'value') {
    filters.value.valueMin = defaults.valueMin;
    filters.value.valueMax = defaults.valueMax;
  } else {
    filters.value[key] = defaults[key];
  }
  await applyFilters();
};

const loadPipelineInboxes = async pipelineId => {
  if (!canManagePipelines.value || !pipelineId) {
    pipelineInboxes.value = [];
    return [];
  }

  try {
    const links = await store.dispatch(
      'crmKanban/fetchPipelineInboxes',
      pipelineId
    );
    pipelineInboxes.value = links;
    return links;
  } catch {
    pipelineInboxes.value = [];
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_INBOX_LOAD_ERROR'));
    return [];
  }
};

const openCreatePipelineDrawer = () => {
  pipelineDrawerMode.value = 'create';
  pipelineInboxes.value = [];
  showPipelineDrawer.value = true;
};

const openEditPipelineDrawer = async () => {
  if (!selectedPipeline.value) return;
  pipelineDrawerMode.value = 'edit';
  pipelineInboxes.value = [];
  showPipelineDrawer.value = true;
  await loadPipelineInboxes(selectedPipeline.value.id);
};

const closePipelineDrawer = () => {
  showPipelineDrawer.value = false;
};

const openHandoffSettings = () => {
  if (!selectedPipeline.value) return;
  router.push({
    name: 'crm_handoff_settings_edit',
    params: { pipelineId: selectedPipeline.value.id },
  });
};

const askConfirmation = async config => {
  confirmConfig.value = config;
  return confirmModal.value?.showConfirmation();
};

const savePipeline = async payload => {
  try {
    const pipeline = await store.dispatch(
      'crmKanban/savePipelineWithStages',
      payload
    );
    currentPipelineId.value = pipeline.id;
    closePipelineDrawer();
    useAlert(
      pipelineDrawerMode.value === 'edit'
        ? t('CRM_KANBAN.ALERTS.PIPELINE_UPDATED')
        : t('CRM_KANBAN.ALERTS.PIPELINE_CREATED')
    );
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_SAVE_ERROR'));
  }
};

const addPipelineInbox = async payload => {
  try {
    const link = await store.dispatch('crmKanban/createPipelineInbox', payload);
    pipelineInboxes.value = [...pipelineInboxes.value, link];
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_INBOX_ADDED'));
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_INBOX_SAVE_ERROR'));
  }
};

const removePipelineInbox = async payload => {
  try {
    await store.dispatch('crmKanban/deletePipelineInbox', payload);
    pipelineInboxes.value = pipelineInboxes.value.filter(
      item => Number(item.inbox_id) !== Number(payload.inboxId)
    );
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_INBOX_REMOVED'));
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_INBOX_REMOVE_ERROR'));
  }
};

const loadPipelineStagesForSettings = async pipelineId => {
  if (!pipelineId || inboxSettingStagesByPipeline.value[String(pipelineId)]) {
    return inboxSettingStagesByPipeline.value[String(pipelineId)] || [];
  }

  const loadedStages = await store.dispatch(
    'crmKanban/fetchPipelineStages',
    pipelineId
  );
  inboxSettingStagesByPipeline.value = {
    ...inboxSettingStagesByPipeline.value,
    [String(pipelineId)]: loadedStages,
  };
  return loadedStages;
};

const loadInboxSettings = async () => {
  try {
    const settings = await store.dispatch('crmKanban/fetchInboxSettings');
    inboxSettings.value = settings;
    await Promise.all(
      settings
        .map(setting => setting.default_pipeline_id)
        .filter(Boolean)
        .map(loadPipelineStagesForSettings)
    );
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.INBOX_SETTINGS_LOAD_ERROR'));
  }
};

const openInboxSettingsDrawer = async () => {
  showInboxSettingsDrawer.value = true;
  await loadInboxSettings();
};

const closeInboxSettingsDrawer = () => {
  showInboxSettingsDrawer.value = false;
};

const openBookingProfilesDrawer = () => {
  showBookingProfilesDrawer.value = true;
};

const closeBookingProfilesDrawer = () => {
  showBookingProfilesDrawer.value = false;
};

const saveInboxSetting = async payload => {
  try {
    if (payload.default_pipeline_id) {
      await loadPipelineStagesForSettings(payload.default_pipeline_id);
    }
    const setting = await store.dispatch(
      'crmKanban/updateInboxSetting',
      payload
    );
    const otherSettings = inboxSettings.value.filter(
      item => Number(item.inbox_id) !== Number(setting.inbox_id)
    );
    inboxSettings.value = [...otherSettings, setting];
    useAlert(t('CRM_KANBAN.ALERTS.INBOX_SETTINGS_SAVED'));
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.INBOX_SETTINGS_SAVE_ERROR'));
  }
};

const archivePipeline = async () => {
  if (!selectedPipeline.value?.id) return;
  const confirmed = await askConfirmation({
    title: t('CRM_KANBAN.CONFIRM.ARCHIVE_PIPELINE_TITLE'),
    description: t('CRM_KANBAN.CONFIRM.ARCHIVE_PIPELINE_DESCRIPTION'),
    confirmLabel: t('CRM_KANBAN.CONFIRM.ARCHIVE_PIPELINE_CONFIRM'),
  });
  if (!confirmed) return;

  try {
    const nextPipeline = await store.dispatch(
      'crmKanban/archivePipeline',
      selectedPipeline.value.id
    );
    currentPipelineId.value = nextPipeline?.id || '';
    closePipelineDrawer();
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_ARCHIVED'));
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.PIPELINE_ARCHIVE_ERROR'));
  }
};

const deleteStage = async stage => {
  const confirmed = await askConfirmation({
    title: t('CRM_KANBAN.CONFIRM.DELETE_STAGE_TITLE'),
    description: t('CRM_KANBAN.CONFIRM.DELETE_STAGE_DESCRIPTION', {
      stage: stage.name,
    }),
    confirmLabel: t('CRM_KANBAN.CONFIRM.DELETE_STAGE_CONFIRM'),
  });
  if (!confirmed) return;

  try {
    await store.dispatch('crmKanban/deleteStage', stage.id);
    useAlert(t('CRM_KANBAN.ALERTS.STAGE_DELETED'));
    await loadCurrentBoard(true);
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.STAGE_DELETE_ERROR'));
  }
};

const openCreateDrawer = () => {
  selectedCard.value = null;
  drawerInitialTab.value = null;
  drawerMode.value = 'create';
  showDrawer.value = true;
};

const openCardDrawer = async (card, { initialTab = null } = {}) => {
  drawerInitialTab.value = initialTab;
  selectedCard.value = card;
  drawerMode.value = 'edit';
  showDrawer.value = true;
  try {
    const [detailedCard] = await Promise.all([
      store.dispatch('crmKanban/fetchCard', card.id),
      store.dispatch('crmKanban/fetchFollowUps', { card_id: card.id }),
    ]);
    if (showDrawer.value && selectedCard.value?.id === card.id) {
      selectedCard.value = detailedCard;
    }
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.CARD_LOAD_ERROR'));
  }
};

const openRouteCardIfNeeded = async () => {
  const cardId = route.query.card_id;
  if (!cardId || openedRouteCardId.value === String(cardId)) return;

  openedRouteCardId.value = String(cardId);
  await openCardDrawer({ id: Number(cardId) });
};

const closeDrawer = () => {
  showDrawer.value = false;
  selectedCard.value = null;
};

// Re-fetch the open card after a child action mutated it server-side (e.g. the
// AI auto-follow-up RESET re-arms the cadence). Mirrors the closeCardDeal
// refresh pattern and also reloads the follow-ups list shown in the drawer.
const refreshSelectedCard = async () => {
  const cardId = selectedCard.value?.id;
  if (!cardId) return;
  try {
    const [detailedCard] = await Promise.all([
      store.dispatch('crmKanban/fetchCard', cardId),
      store.dispatch('crmKanban/fetchFollowUps', { card_id: cardId }),
    ]);
    if (detailedCard && selectedCard.value?.id === cardId) {
      selectedCard.value = detailedCard;
    }
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.CARD_LOAD_ERROR'));
  }
};

const saveCard = async payload => {
  try {
    if (drawerMode.value === 'edit') {
      await store.dispatch('crmKanban/updateCard', {
        id: selectedCard.value.id,
        ...payload,
      });
      useAlert(t('CRM_KANBAN.ALERTS.CARD_UPDATED'));
    } else {
      await store.dispatch('crmKanban/createCard', payload);
      useAlert(t('CRM_KANBAN.ALERTS.CARD_CREATED'));
    }
    closeDrawer();
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.CARD_SAVE_ERROR'));
  }
};

const cardDrawerRef = ref(null);

// Follow-up CRUD from the card drawer mutates the calendar's data source, so
// keep the calendar in sync when it's the active view (it reads a separate
// calendarEvents array, not the drawer's follow-up list).
const syncCalendarIfActive = async () => {
  if (viewMode.value === 'calendar') await loadCurrentCalendar();
};

const createFollowUp = async payload => {
  try {
    await store.dispatch('crmKanban/createFollowUp', payload);
    await store.dispatch('crmKanban/fetchFollowUps', {
      card_id: selectedCard.value.id,
    });
    cardDrawerRef.value?.resetFollowUpForm?.();
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_CREATED'));
    await syncCalendarIfActive();
  } catch (error) {
    const apiMessage = error?.response?.data?.message;
    useAlert(apiMessage || t('CRM_KANBAN.ALERTS.FOLLOW_UP_SAVE_ERROR'));
  }
};

const completeFollowUp = async followUp => {
  try {
    await store.dispatch('crmKanban/completeFollowUp', followUp.id);
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_COMPLETED'));
    await syncCalendarIfActive();
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_SAVE_ERROR'));
  }
};

const cancelFollowUp = async followUp => {
  try {
    await store.dispatch('crmKanban/cancelFollowUp', followUp.id);
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_CANCELED'));
    await syncCalendarIfActive();
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_SAVE_ERROR'));
  }
};

const archiveCard = async () => {
  if (!selectedCard.value?.id) return;
  try {
    await store.dispatch('crmKanban/archiveCard', selectedCard.value.id);
    useAlert(t('CRM_KANBAN.ALERTS.CARD_ARCHIVED'));
    closeDrawer();
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.CARD_ARCHIVE_ERROR'));
  }
};

const CLOSE_ALERT_KEYS = {
  won: 'CARD_WON',
  lost: 'CARD_LOST',
  reopen: 'CARD_REOPENED',
};

const closeCardDeal = async payload => {
  const cardId = selectedCard.value?.id;
  if (!cardId) return;
  try {
    await store.dispatch('crmKanban/closeCard', { id: cardId, ...payload });
    // Refresh drawer detail so the timeline shows the won/lost/reopen activity.
    const detailedCard = await store.dispatch('crmKanban/fetchCard', cardId);
    if (selectedCard.value?.id === cardId) {
      selectedCard.value = detailedCard;
    }
    useAlert(t(`CRM_KANBAN.ALERTS.${CLOSE_ALERT_KEYS[payload.result]}`));
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.CARD_CLOSE_ERROR'));
  }
};

const onDragStart = () => {
  dragSnapshot.value = JSON.parse(JSON.stringify(stages.value));
};

const onDragChange = async (stage, event) => {
  if (!event.added) return;
  const movedCard = event.added.element;
  try {
    await store.dispatch('crmKanban/moveCard', {
      cardId: movedCard.id,
      stageId: stage.id,
    });
    useAlert(t('CRM_KANBAN.ALERTS.CARD_MOVED'));
  } catch {
    store.commit('crmKanban/RESTORE_CRM_KANBAN_STAGES', dragSnapshot.value);
    useAlert(t('CRM_KANBAN.ALERTS.CARD_MOVE_ERROR'));
  } finally {
    dragSnapshot.value = null;
  }
};

const loadMore = async stage => {
  if (!stage.has_more || !stage.next_cursor) return;
  loadError.value = '';
  try {
    await store.dispatch('crmKanban/fetchBoard', {
      pipelineId: currentPipelineId.value,
      cursorByStage: { [stage.id]: stage.next_cursor },
      stageIds: [stage.id],
      append: true,
    });
  } catch {
    loadError.value = t('CRM_KANBAN.ERRORS.PAGINATION', {
      stage: stage.name,
    });
    useAlert(loadError.value);
  }
};

/* -------------------------------------------------------------------------- */
/* List (v2) — TanStack table wiring                                          */
/* -------------------------------------------------------------------------- */
const collapsedGroups = ref([]);

// TanStack column defs, rebuilt when stages/agents change so editors get fresh
// option lists. Labels resolve through CRM_KANBAN.LIST.COLUMNS.* i18n.
const cardColumnDefs = computed(() =>
  buildCrmCardColumns({ t, stages: stages.value, agents: agents.value })
);

// Merge persisted listPrefs with the column defaults so the table always has a
// complete state object (visibility/order/sizing/density).
const listColumnState = computed(() => {
  const prefs = listPrefs.value || {};
  return {
    columnVisibility: {
      ...DEFAULT_COLUMN_VISIBILITY,
      ...(prefs.columnVisibility || {}),
    },
    columnOrder:
      prefs.columnOrder && prefs.columnOrder.length
        ? prefs.columnOrder
        : DEFAULT_COLUMN_ORDER,
    columnSizing: prefs.columnSizing || {},
    density: prefs.density || 'comfortable',
  };
});

// Column descriptors for the settings menu: { id, label, visible, hideable }.
const columnSettingsItems = computed(() => {
  const state = listColumnState.value;
  const byId = new Map(cardColumnDefs.value.map(col => [col.id, col]));
  return state.columnOrder
    .filter(id => id !== 'select' && byId.has(id))
    .map(id => {
      const col = byId.get(id);
      return {
        id,
        label: col.header || id,
        visible: state.columnVisibility[id] !== false,
        hideable: col.enableHiding !== false,
      };
    });
});

const hasActiveFilters = computed(() => activeFilterCount.value > 0);

const persistListPrefs = patch => {
  store.dispatch('crmKanban/setListPrefs', {
    pipelineId: currentPipelineId.value,
    ...listColumnState.value,
    ...patch,
  });
};

const onListSortChange = async payload => {
  store.dispatch('crmKanban/setListSort', payload || null);
  await loadCurrentList();
};

const onListGroupChange = ({ groupBy, collapsed }) => {
  if (groupBy !== undefined)
    store.dispatch('crmKanban/setListGroupBy', groupBy);
  if (collapsed !== undefined) collapsedGroups.value = collapsed;
};

const onListColumnChange = ({ columnSizing }) => {
  if (columnSizing) persistListPrefs({ columnSizing });
};

const onListSelectChange = ids => {
  store.dispatch('crmKanban/setListSelection', ids);
};

// CrmTableCellEditable reports intent {cardId|field, value}; route through the
// store wrapper which handles stage→move, won/lost→close, value-source lock.
const onListEditSave = async ({ cardId, field, value }) => {
  try {
    if (field === 'next_follow_up_at') {
      await store.dispatch('crmKanban/updateCardFields', {
        id: cardId,
        expected_close_at: undefined,
        next_follow_up_at: value,
      });
    } else {
      await store.dispatch('crmKanban/updateCardFields', {
        id: cardId,
        [field === 'value' ? 'value_cents' : field]: value,
      });
    }
    useAlert(t('CRM_KANBAN.EDIT.SAVED'));
  } catch {
    useAlert(t('CRM_KANBAN.EDIT.ERROR'));
  }
};

// Column-settings menu emits the full next state, or { reset: true }.
const onColumnSettingsUpdate = update => {
  if (update.reset) {
    persistListPrefs({
      columnVisibility: { ...DEFAULT_COLUMN_VISIBILITY },
      columnOrder: [...DEFAULT_COLUMN_ORDER],
      density: 'comfortable',
    });
    return;
  }
  const patch = {};
  if (update.columns) {
    patch.columnOrder = ['select', ...update.columns.map(c => c.id)];
    patch.columnVisibility = update.columns.reduce(
      (acc, c) => ({ ...acc, [c.id]: c.visible }),
      { select: true }
    );
  }
  if (update.density) patch.density = update.density;
  persistListPrefs(patch);
};

/* -------------------------------------------------------------------------- */
/* Saved views (v2) — list-view-only                                          */
/* -------------------------------------------------------------------------- */
// Current list state serialized as a saved-view config. Shape matches the
// jsonb contract: { columns, filters, sort, group_by, density }.
const currentSavedViewConfig = computed(() => ({
  columns: {
    columnVisibility: listColumnState.value.columnVisibility,
    columnOrder: listColumnState.value.columnOrder,
    columnSizing: listColumnState.value.columnSizing,
  },
  filters: { ...filters.value },
  sort: listSort.value || null,
  group_by: listGroupBy.value || 'none',
  density: listColumnState.value.density,
}));

const fetchSavedViews = () => {
  if (!currentPipelineId.value) return;
  store.dispatch('crmKanban/fetchSavedViews', currentPipelineId.value);
};

// Apply a chosen view: restore the page's column/filter/sort/group state from
// its config, then reload the list with the new state.
const onSavedViewApply = async ({ view }) => {
  const config = view?.config || {};
  if (config.columns) {
    persistListPrefs({
      columnVisibility:
        config.columns.columnVisibility || DEFAULT_COLUMN_VISIBILITY,
      columnOrder: config.columns.columnOrder || DEFAULT_COLUMN_ORDER,
      columnSizing: config.columns.columnSizing || {},
      ...(config.density ? { density: config.density } : {}),
    });
  }
  store.dispatch('crmKanban/setListSort', config.sort || null);
  store.dispatch('crmKanban/setListGroupBy', config.group_by || 'none');
  if (config.filters) {
    filters.value = { ...defaultFilters(), ...config.filters };
    await store.dispatch('crmKanban/setFilters', filters.value);
  }
  await loadCurrentList();
};

const onSavedViewCreate = async payload => {
  try {
    await store.dispatch('crmKanban/saveSavedView', payload);
    useAlert(t('CRM_KANBAN.EDIT.SAVED'));
  } catch {
    useAlert(t('CRM_KANBAN.EDIT.ERROR'));
  }
};

const onSavedViewUpdate = async payload => {
  try {
    await store.dispatch('crmKanban/saveSavedView', payload);
    useAlert(t('CRM_KANBAN.EDIT.SAVED'));
  } catch {
    useAlert(t('CRM_KANBAN.EDIT.ERROR'));
  }
};

const onSavedViewDelete = async ({ id }) => {
  try {
    await store.dispatch('crmKanban/deleteSavedView', id);
    useAlert(t('CRM_KANBAN.EDIT.SAVED'));
  } catch {
    useAlert(t('CRM_KANBAN.EDIT.ERROR'));
  }
};

const runBulkAction = async (action, payload = {}) => {
  try {
    await store.dispatch('crmKanban/bulkAction', {
      ids: listSelection.value,
      action,
      payload,
    });
    useAlert(t('CRM_KANBAN.BULK.DONE', { count: listSelection.value.length }));
  } catch {
    useAlert(t('CRM_KANBAN.EDIT.ERROR'));
  }
};

const onBulkMove = ({ stageId }) =>
  runBulkAction('move', { stage_id: stageId });
const onBulkAssign = ({ ownerId }) =>
  runBulkAction('assign', { owner_id: ownerId });
const onBulkStatus = ({ value }) => runBulkAction('status', { result: value });
const onBulkArchive = () => runBulkAction('delete');
const onBulkClear = () => store.dispatch('crmKanban/setListSelection', []);

/* -------------------------------------------------------------------------- */
/* Calendar (v2) wiring                                                       */
/* -------------------------------------------------------------------------- */
// The calendar emits the visible window; persist it then refetch that range.
const onCalendarRangeChange = async ({ from, to, includeCompleted }) => {
  store.dispatch('crmKanban/setCalendarRange', { from, to });
  if (includeCompleted !== undefined) {
    store.dispatch('crmKanban/setCalendarIncludeCompleted', includeCompleted);
  }
  await loadCurrentCalendar();
};

const onCalendarViewChange = view => {
  store.dispatch('crmKanban/setCalendarView', view);
};

const showMeetingDetail = ref(false);
const selectedMeetingEvent = ref(null);
const isMeetingEvent = event => event?.event_type === 'meeting';

// Open the existing card drawer from a calendar event (reuses openCardDrawer).
// Land on the tab that matches the event: follow-up/reminder events open on the
// Follow-ups tab; expected-close (Previsão) events on Resumo, where that field lives.
const onCalendarOpenEvent = event => {
  if (isMeetingEvent(event)) {
    selectedMeetingEvent.value = event;
    showMeetingDetail.value = true;
    return;
  }

  if (!event?.card_id) return;
  const initialTab = String(event.event_type || '').startsWith('follow_up')
    ? 'followups'
    : 'summary';
  openCardDrawer({ id: event.card_id }, { initialTab });
};

// Quick-add: clicking a day (or "+ Novo") opens the lightweight reminder popover,
// pre-filled with that date. Creating a deal still lives in the full drawer
// ("Mais opções" / the Kanban "+ Novo card").
const showQuickAdd = ref(false);
const quickAddDate = ref(new Date());
const quickAddType = ref('reminder');
const showMeetingScheduler = ref(false);
const meetingSchedulerCard = ref(null);
const meetingSchedulerDate = ref(new Date());
// When set, the scheduler mounts in reschedule mode prefilled from this meeting.
const meetingSchedulerMeeting = ref(null);

// Install-level flag (exposed in window.globalConfig, like CRM_KANBAN_ENABLED).
// Meetings are available to every account when this flag is on; each account
// schedules through its own connected Google/Microsoft calendar mailbox
// (Crm::Config.calendar_meetings_enabled? is ENV-only).
const isMeetingFeatureEnabled = computed(
  () => window.globalConfig?.[CRM_CALENDAR_MEETINGS_FEATURE] === 'true'
);
const userTimezone = computed(
  () => Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC'
);

const openMeetingScheduler = async ({ card, cardId, date } = {}) => {
  if (!isMeetingFeatureEnabled.value) return;

  showQuickAdd.value = false;
  const id = card?.id || cardId || selectedCard.value?.id;
  if (!id) {
    openCreateDrawer();
    return;
  }

  meetingSchedulerCard.value = card || { id };
  meetingSchedulerDate.value = date || new Date();

  try {
    const detailedCard =
      card?.title && card?.contact
        ? card
        : await store.dispatch('crmKanban/fetchCard', id);
    if (
      detailedCard?.id === Number(id) ||
      String(detailedCard?.id) === String(id)
    ) {
      meetingSchedulerCard.value = detailedCard;
    }
  } catch {
    useAlert(t('CRM_KANBAN.ALERTS.CARD_LOAD_ERROR'));
  }

  showMeetingScheduler.value = true;
};

const closeMeetingScheduler = () => {
  showMeetingScheduler.value = false;
  meetingSchedulerMeeting.value = null;
};

const closeMeetingDetail = () => {
  showMeetingDetail.value = false;
  selectedMeetingEvent.value = null;
};

const scheduleMeeting = async () => {
  closeMeetingScheduler();
  useAlert(t('CRM_KANBAN.CALENDAR.MEETING_SCHEDULER.SUCCESS'));
  await refreshSelectedCard();
  await syncCalendarIfActive();
};

// Reschedule success (scheduler @updated): refresh the card + calendar in
// realtime (like cal12) and close any open meeting detail drawer.
const onMeetingRescheduled = async () => {
  closeMeetingScheduler();
  closeMeetingDetail();
  useAlert(t('CRM_KANBAN.CALENDAR.MEETING_DETAIL.RESCHEDULED_TOAST'));
  await refreshSelectedCard();
  await syncCalendarIfActive();
};

// Opens the scheduler in reschedule mode for a meeting. Fetches the full meeting
// (guests/inbox/times) when we only have the lightweight calendar event. An
// optional date prefills a new day/time from a calendar drag (always confirmed).
const openMeetingReschedule = async (meetingLike, date) => {
  if (!isMeetingFeatureEnabled.value) return;

  const rawId = String(
    meetingLike?.meeting_id || meetingLike?.id || ''
  ).replace(/^meeting_/, '');
  if (!rawId) return;

  let meeting = meetingLike;
  try {
    const { data } = await crmMeetingsAPI.show(currentAccountId.value, rawId);
    meeting = data?.payload || meetingLike;
  } catch {
    useAlert(t('CRM_KANBAN.CALENDAR.MEETING_DETAIL.ERRORS.LOAD_FAILED'));
    return;
  }

  if (date) {
    const next = date instanceof Date ? date : new Date(date);
    if (!Number.isNaN(next.getTime())) {
      const start = new Date(meeting.starts_at || next);
      const end = new Date(meeting.ends_at || next);
      const durationMs = end > start ? end - start : 30 * 60 * 1000;
      meeting = {
        ...meeting,
        starts_at: next.toISOString(),
        ends_at: new Date(next.getTime() + durationMs).toISOString(),
      };
    }
  }

  meetingSchedulerMeeting.value = meeting;
  meetingSchedulerCard.value = { id: meeting.card_id };
  meetingSchedulerDate.value = meeting.starts_at
    ? new Date(meeting.starts_at)
    : new Date();
  showMeetingScheduler.value = true;
};

const onCalendarQuickAdd = (payload = {}) => {
  quickAddDate.value = payload.date ? new Date(payload.date) : new Date();
  quickAddType.value = payload.type || 'reminder';
  showQuickAdd.value = true;
};

const onQuickAddCreate = async ({ cardId, title, dueAt }) => {
  try {
    await store.dispatch('crmKanban/createFollowUp', {
      card_id: cardId,
      title,
      follow_up_type: 'task',
      automation_mode: 'reminder_only',
      due_at: dueAt,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC',
    });
    showQuickAdd.value = false;
    useAlert(t('CRM_KANBAN.ALERTS.FOLLOW_UP_CREATED'));
    await loadCurrentCalendar();
  } catch (error) {
    const apiMessage = error?.response?.data?.message;
    useAlert(apiMessage || t('CRM_KANBAN.ALERTS.FOLLOW_UP_SAVE_ERROR'));
  }
};

const onQuickAddScheduleMeeting = ({ cardId, date } = {}) => {
  showQuickAdd.value = false;
  openMeetingScheduler({ cardId, date: date || quickAddDate.value });
};

const onDrawerScheduleMeeting = ({ cardId } = {}) => {
  openMeetingScheduler({ card: selectedCard.value, cardId, date: new Date() });
};

// "Continuar" (WhatsApp/Previsão) and "Mais opções": when a deal is already
// picked, open THAT card's drawer on the relevant tab (WhatsApp → Follow-ups;
// Previsão → Resumo, where the expected-close field lives). Reunião opens the
// standalone scheduler. With no deal chosen, fall back to a fresh card.
const onQuickAddMoreOptions = ({ cardId, type } = {}) => {
  showQuickAdd.value = false;
  if (type === 'meeting') {
    onQuickAddScheduleMeeting({ cardId, date: quickAddDate.value });
    return;
  }

  if (cardId) {
    const initialTab = type === 'closeDate' ? 'summary' : 'followups';
    openCardDrawer({ id: cardId }, { initialTab });
  } else {
    openCreateDrawer();
  }
};

const SNOOZE_PRESET_MS = {
  '1h': 60 * 60 * 1000,
  tomorrow: 24 * 60 * 60 * 1000,
  next_week: 7 * 24 * 60 * 60 * 1000,
};

// Reschedule from a calendar drag/snooze. expected_close mutates the deal date
// (PATCH card); follow-up events go through the reschedule action (WhatsApp
// past-guard server-side). `date` may be a Date, ISO string, or snooze preset.
const onCalendarReschedule = async ({ event, date }) => {
  if (isMeetingEvent(event)) {
    // Never silently PATCH a meeting on drag — open the scheduler in reschedule
    // mode with the dragged-to date/time prefilled so the user confirms.
    let nextDate;
    if (date instanceof Date) {
      nextDate = date;
    } else if (SNOOZE_PRESET_MS[date]) {
      nextDate = new Date(Date.now() + SNOOZE_PRESET_MS[date]);
    } else if (date) {
      nextDate = new Date(date);
    }
    await openMeetingReschedule(event, nextDate);
    return;
  }

  try {
    const isCloseDate = event.event_type === 'expected_close';
    let nextIso;
    if (date instanceof Date) {
      nextIso = date.toISOString();
    } else if (SNOOZE_PRESET_MS[date]) {
      nextIso = new Date(Date.now() + SNOOZE_PRESET_MS[date]).toISOString();
    } else {
      nextIso = new Date(date).toISOString();
    }

    if (isCloseDate) {
      await store.dispatch('crmKanban/updateCardFields', {
        id: event.card_id,
        expected_close_at: nextIso,
      });
    } else {
      const followUpId = String(event.id).replace(/^follow_up_/, '');
      await store.dispatch('crmKanban/rescheduleFollowUp', {
        id: followUpId,
        dueAt: nextIso,
      });
    }
    await loadCurrentCalendar();
  } catch {
    useAlert(t('CRM_KANBAN.CALENDAR.RESCHEDULE_ERROR'));
  }
};

const onMeetingOpenCard = meeting => {
  closeMeetingDetail();
  if (meeting?.card_id) openCardDrawer({ id: meeting.card_id });
};

const onMeetingReschedule = async meeting => {
  const target = meeting || selectedMeetingEvent.value;
  closeMeetingDetail();
  await openMeetingReschedule(target);
};

const onMeetingCanceled = async () => {
  closeMeetingDetail();
  await refreshSelectedCard();
  await syncCalendarIfActive();
};

// After an outcome (held/no-show) is recorded, keep the detail open but refresh
// the card + calendar so the change is reflected without an F5 (cal12 pattern).
const onMeetingUpdated = async () => {
  await refreshSelectedCard();
  await syncCalendarIfActive();
};

watch(currentPipelineId, async (newPipelineId, oldPipelineId) => {
  if (newPipelineId && newPipelineId !== oldPipelineId) {
    // Rehydrate per-pipeline column layout from localStorage and clear stale
    // list selection before loading the new pipeline's active view.
    store.dispatch('crmKanban/loadListPrefs', newPipelineId);
    store.dispatch('crmKanban/setListSelection', []);
    fetchSavedViews();
    await loadActiveView(true);
  }
});

watch(viewMode, async () => {
  await loadActiveView(true);
});

watch(
  () => route.query.card_id,
  () => {
    openRouteCardIfNeeded();
  }
);

const setViewMode = mode => {
  viewMode.value = mode;
};

useEmitter(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED, handleRealtimeConnected);
useEmitter(BUS_EVENTS.CRM_BOARD_REFETCH, handleServerFilterRefetch);

onMounted(async () => {
  await refreshData();
  // Seed the per-pipeline column layout for the resolved initial pipeline.
  if (currentPipelineId.value) {
    store.dispatch('crmKanban/loadListPrefs', currentPipelineId.value);
    fetchSavedViews();
  }
  await openRouteCardIfNeeded();
});
</script>

<template>
  <main class="flex h-full min-w-0 flex-col overflow-hidden bg-n-background">
    <header
      class="flex flex-col gap-3 border-b border-n-weak px-8 py-3 lg:flex-row lg:flex-wrap lg:items-center lg:justify-between"
    >
      <div class="min-w-0">
        <h1 class="mb-0 text-2xl font-medium text-n-slate-12">
          {{
            isCalendarOnly ? t('SIDEBAR.CRM_CALENDAR') : t('CRM_KANBAN.TITLE')
          }}
        </h1>
      </div>
      <div class="flex shrink-0 flex-wrap items-center gap-2">
        <div
          v-if="!isCalendarOnly"
          class="flex items-center rounded-lg bg-n-alpha-black2 p-1"
        >
          <button
            v-for="mode in viewModeOptions"
            :key="mode.id"
            type="button"
            class="inline-flex h-8 items-center gap-1.5 rounded-md px-3 text-xs font-medium text-n-slate-11 transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12"
            :class="
              viewMode === mode.id
                ? 'bg-n-surface-2 text-n-slate-12 shadow-sm'
                : ''
            "
            @click="setViewMode(mode.id)"
          >
            <span :class="mode.icon" class="size-3.5" />
            {{ mode.label }}
          </button>
        </div>
        <Button
          icon="i-lucide-refresh-cw"
          slate
          faded
          :title="t('CRM_KANBAN.ACTIONS.REFRESH')"
          :disabled="isLoading"
          @click="refreshData"
        />
        <Button
          v-if="canManagePipelines"
          :label="t('CRM_KANBAN.ACTIONS.INBOX_SETTINGS')"
          icon="i-lucide-shield-check"
          slate
          faded
          :disabled="isLoading"
          @click="openInboxSettingsDrawer"
        />
        <Button
          v-if="canManagePipelines && isMeetingFeatureEnabled"
          :label="t('CRM_KANBAN.BOOKING.ADMIN.ACTION')"
          icon="i-lucide-calendar-clock"
          slate
          faded
          :disabled="isLoading"
          @click="openBookingProfilesDrawer"
        />
        <Button
          v-if="canManagePipelines && !isCalendarOnly"
          :label="t('CRM_KANBAN.ACTIONS.NEW_PIPELINE')"
          icon="i-lucide-kanban"
          slate
          faded
          :disabled="isLoading"
          @click="openCreatePipelineDrawer"
        />
      </div>
    </header>

    <section
      v-if="viewMode !== 'calendar'"
      class="flex flex-col gap-3 border-b border-n-weak px-8 py-4"
    >
      <!-- Single control row: pipeline picker + Edit pipeline + search + 2
           high-frequency selects + Filters popover + clear, with New card pushed
           to the right. Keeps the header band to just the title + global actions. -->
      <div class="flex flex-wrap items-end gap-3">
        <label v-if="viewMode !== 'calendar'" class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('CRM_KANBAN.FILTERS.PIPELINE') }}
          </span>
          <select
            v-model="currentPipelineId"
            class="reset-base !mb-0 h-10 w-44 rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
            :disabled="!hasPipelines"
          >
            <option
              v-for="pipeline in pipelineOptions"
              :key="pipeline.value"
              :value="pipeline.value"
            >
              {{ pipeline.label }}
            </option>
          </select>
        </label>

        <Button
          v-if="
            viewMode !== 'calendar' &&
            selectedPipeline &&
            (canManagePipelines || canManageAi)
          "
          :label="t('CRM_KANBAN.ACTIONS.EDIT_PIPELINE')"
          icon="i-lucide-settings"
          blue
          faded
          @click="openEditPipelineDrawer"
        />

        <Button
          v-if="
            viewMode !== 'calendar' &&
            selectedPipeline &&
            canManageAi &&
            isCrmAiEnabled
          "
          :label="t('CRM_KANBAN.ACTIONS.HANDOFF_SETTINGS')"
          icon="i-lucide-arrow-right-left"
          teal
          solid
          @click="openHandoffSettings"
        />

        <div v-if="viewMode !== 'calendar'" class="w-60">
          <Input
            v-model="filters.search"
            :placeholder="t('CRM_KANBAN.FILTERS.SEARCH_PLACEHOLDER')"
            :label="t('CRM_KANBAN.FILTERS.SEARCH')"
            @enter="applyFilters"
          />
        </div>

        <Popover
          v-if="viewMode !== 'calendar'"
          ref="filtersPopover"
          align="start"
        >
          <template #default>
            <span class="relative inline-flex">
              <Button
                icon="i-lucide-sliders-horizontal"
                :label="t('CRM_KANBAN.ACTIONS.FILTERS')"
                slate
                faded
              />
              <span
                v-if="activeFilterCount"
                class="absolute -right-1.5 -top-1.5 inline-flex h-4 min-w-[1rem] items-center justify-center rounded-full bg-n-brand px-1 text-[10px] font-semibold text-white"
              >
                {{ activeFilterCount }}
              </span>
            </span>
          </template>
          <template #content>
            <div class="flex w-80 flex-col gap-3 p-4">
              <p class="mb-0 text-sm font-medium text-n-slate-12">
                {{ t('CRM_KANBAN.FILTERS.PANEL_TITLE') }}
              </p>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.INBOX') }}
                </span>
                <select
                  v-model="filters.inboxId"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">
                    {{ t('CRM_KANBAN.FILTERS.ALL_FEMININE') }}
                  </option>
                  <option
                    v-for="inbox in inboxOptions"
                    :key="inbox.value"
                    :value="inbox.value"
                  >
                    {{ inbox.label }}
                  </option>
                </select>
              </label>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.OWNER') }}
                </span>
                <select
                  v-model="filters.ownerId"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">{{ t('CRM_KANBAN.FILTERS.ALL') }}</option>
                  <option
                    v-for="agent in agentOptions"
                    :key="agent.value"
                    :value="agent.value"
                  >
                    {{ agent.label }}
                  </option>
                </select>
              </label>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.PRIORITY') }}
                </span>
                <select
                  v-model="filters.priority"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                  @change="applyFilters"
                >
                  <option value="">
                    {{ t('CRM_KANBAN.FILTERS.ALL_FEMININE') }}
                  </option>
                  <option
                    v-for="priority in priorityOptions"
                    :key="priority.value"
                    :value="priority.value"
                  >
                    {{ priority.label }}
                  </option>
                </select>
              </label>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.FOLLOW_UP') }}
                </span>
                <select
                  v-model="filters.followUpStatus"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                  @change="applyFilters"
                >
                  <option value="">{{ t('CRM_KANBAN.FILTERS.ALL') }}</option>
                  <option
                    v-for="status in followUpStatusOptions"
                    :key="status.value"
                    :value="status.value"
                  >
                    {{ status.label }}
                  </option>
                </select>
              </label>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.RESPONSIBLE') }}
                </span>
                <select
                  v-model="filters.responsibleKind"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">{{ t('CRM_KANBAN.FILTERS.ALL') }}</option>
                  <option
                    v-for="option in responsibleOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>
              </label>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.TEAM') }}
                </span>
                <select
                  v-model="filters.teamId"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">{{ t('CRM_KANBAN.FILTERS.ALL') }}</option>
                  <option
                    v-for="team in teamOptions"
                    :key="team.value"
                    :value="team.value"
                  >
                    {{ team.label }}
                  </option>
                </select>
              </label>

              <div class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.STAGE') }}
                </span>
                <div
                  class="flex max-h-28 flex-wrap gap-1.5 overflow-y-auto rounded-lg bg-n-alpha-black2 p-2 outline outline-1 outline-n-weak"
                >
                  <button
                    v-for="stage in stageOptions"
                    :key="stage.value"
                    type="button"
                    class="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium transition-colors"
                    :class="
                      isStageSelected(stage.value)
                        ? 'bg-n-brand text-white'
                        : 'bg-n-alpha-2 text-n-slate-11 hover:text-n-slate-12'
                    "
                    @click="toggleStageFilter(stage.value)"
                  >
                    {{ stage.label }}
                  </button>
                  <span
                    v-if="!stageOptions.length"
                    class="text-xs text-n-slate-10"
                  >
                    {{ t('CRM_KANBAN.FILTERS.STAGE_PLACEHOLDER') }}
                  </span>
                </div>
              </div>

              <div class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.LABELS') }}
                </span>
                <div
                  class="flex max-h-28 flex-wrap gap-1.5 overflow-y-auto rounded-lg bg-n-alpha-black2 p-2 outline outline-1 outline-n-weak"
                >
                  <button
                    v-for="label in labelOptions"
                    :key="label.value"
                    type="button"
                    class="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium transition-colors"
                    :class="
                      isLabelSelected(label.value)
                        ? 'bg-n-brand text-white'
                        : 'bg-n-alpha-2 text-n-slate-11 hover:text-n-slate-12'
                    "
                    @click="toggleLabelFilter(label.value)"
                  >
                    <span
                      class="size-1.5 shrink-0 rounded-full"
                      :style="{ backgroundColor: label.color }"
                    />
                    {{ label.label }}
                  </button>
                  <span
                    v-if="!labelOptions.length"
                    class="text-xs text-n-slate-10"
                  >
                    {{ t('CRM_KANBAN.FILTERS.LABELS_PLACEHOLDER') }}
                  </span>
                </div>
              </div>

              <div class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.CAMPAIGN') }}
                </span>
                <div
                  class="flex max-h-28 flex-wrap gap-1.5 overflow-y-auto rounded-lg bg-n-alpha-black2 p-2 outline outline-1 outline-n-weak"
                >
                  <button
                    v-for="campaign in campaignFilterOptions"
                    :key="campaign.value"
                    type="button"
                    class="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium transition-colors"
                    :class="
                      isCampaignSelected(campaign.value)
                        ? 'bg-n-brand text-white'
                        : 'bg-n-alpha-2 text-n-slate-11 hover:text-n-slate-12'
                    "
                    @click="toggleCampaignFilter(campaign.value)"
                  >
                    {{ campaign.label }} ({{ campaign.count }})
                  </button>
                  <span
                    v-if="!campaignFilterOptions.length"
                    class="text-xs text-n-slate-10"
                  >
                    {{ t('CRM_KANBAN.FILTERS.CAMPAIGN_PLACEHOLDER') }}
                  </span>
                </div>
              </div>

              <div class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.VALUE_RANGE') }}
                </span>
                <div class="flex items-center gap-2">
                  <input
                    v-model="filters.valueMin"
                    type="number"
                    min="0"
                    :placeholder="t('CRM_KANBAN.FILTERS.VALUE_MIN')"
                    class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                  />
                  <span
                    class="i-lucide-minus size-3 shrink-0 text-n-slate-10"
                  />
                  <input
                    v-model="filters.valueMax"
                    type="number"
                    min="0"
                    :placeholder="t('CRM_KANBAN.FILTERS.VALUE_MAX')"
                    class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                  />
                </div>
              </div>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.STALE') }}
                </span>
                <select
                  v-model="filters.staleDays"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">
                    {{ t('CRM_KANBAN.FILTERS.STALE_PLACEHOLDER') }}
                  </option>
                  <option
                    v-for="option in staleOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>
              </label>

              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.LINKED') }}
                </span>
                <select
                  v-model="filters.standalone"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">{{ t('CRM_KANBAN.FILTERS.ALL') }}</option>
                  <option
                    v-for="option in linkedOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>
              </label>

              <label
                v-if="canManageAi"
                class="flex items-center gap-2 text-sm text-n-slate-12"
              >
                <input
                  v-model="filters.aiPending"
                  type="checkbox"
                  class="size-4 rounded border-n-weak text-n-brand focus:ring-n-brand"
                />
                {{ t('CRM_KANBAN.FILTERS.AI_PENDING') }}
              </label>

              <label v-if="viewMode === 'list'" class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.FILTERS.RESULT') }}
                </span>
                <select
                  v-model="filters.result"
                  class="reset-base !mb-0 h-9 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                >
                  <option value="">{{ t('CRM_KANBAN.FILTERS.ALL') }}</option>
                  <option
                    v-for="result in resultOptions"
                    :key="result.value"
                    :value="result.value"
                  >
                    {{ result.label }}
                  </option>
                </select>
              </label>

              <div class="flex items-center justify-between gap-2 pt-1">
                <Button
                  :label="t('CRM_KANBAN.ACTIONS.CLEAR_FILTERS')"
                  slate
                  ghost
                  sm
                  @click="clearFilters"
                />
                <Button
                  :label="t('CRM_KANBAN.ACTIONS.APPLY_FILTERS')"
                  sm
                  @click="applyFiltersFromPopover"
                />
              </div>
            </div>
          </template>
        </Popover>

        <Button
          v-if="activeFilterCount && viewMode !== 'calendar'"
          icon="i-lucide-x"
          slate
          faded
          :title="t('CRM_KANBAN.ACTIONS.CLEAR_FILTERS')"
          @click="clearFilters"
        />

        <!-- New card sits at the right of the control row. With active filters the
             row wraps and this button drops to the next line as a whole (never
             splitting), thanks to flex-wrap + ml-auto. -->
        <Button
          v-if="canManageCards && viewMode !== 'calendar'"
          class="ml-auto"
          :label="t('CRM_KANBAN.ACTIONS.NEW_CARD')"
          icon="i-lucide-plus"
          :disabled="!hasPipelines || isLoading"
          @click="openCreateDrawer"
        />
      </div>

      <!-- Active-filter chips -->
      <div
        v-if="activeFilterChips.length && viewMode !== 'calendar'"
        class="flex flex-wrap gap-2"
      >
        <button
          v-for="chip in activeFilterChips"
          :key="chip.key"
          type="button"
          class="inline-flex items-center gap-1.5 rounded-full bg-n-alpha-2 px-2.5 py-1 text-xs font-medium text-n-slate-12 hover:bg-n-alpha-3"
          @click="removeFilterChip(chip.key)"
        >
          {{ chip.label }}
          <span class="i-lucide-x size-3 text-n-slate-10" />
        </button>
      </div>
    </section>

    <section
      v-if="loadError && hasBoardContent"
      class="flex items-center justify-between gap-3 border-b border-n-weak bg-n-ruby-2 px-8 py-3 text-sm"
    >
      <div class="min-w-0">
        <p class="mb-0 font-medium text-n-ruby-11">
          {{ t('CRM_KANBAN.ERRORS.TITLE') }}
        </p>
        <p class="mb-0 truncate text-xs text-n-ruby-10">
          {{ loadError }}
        </p>
      </div>
      <Button
        :label="t('CRM_KANBAN.ERRORS.RETRY')"
        icon="i-lucide-refresh-cw"
        ruby
        faded
        sm
        @click="refreshData"
      />
    </section>

    <div v-if="isLoading" class="flex flex-1 items-center justify-center">
      <Spinner />
    </div>

    <section
      v-else-if="loadError && !hasBoardContent"
      class="flex flex-1 items-center justify-center px-8"
    >
      <div class="max-w-xl text-center">
        <p class="mb-2 text-lg font-medium text-n-ruby-11">
          {{ t('CRM_KANBAN.ERRORS.TITLE') }}
        </p>
        <p class="mb-5 text-sm leading-6 text-n-slate-11">
          {{ loadError }}
        </p>
        <Button
          :label="t('CRM_KANBAN.ERRORS.RETRY')"
          icon="i-lucide-refresh-cw"
          @click="refreshData"
        />
      </div>
    </section>

    <section
      v-else-if="!hasPipelines"
      class="flex flex-1 items-center justify-center px-8"
    >
      <div class="max-w-xl text-center">
        <p class="mb-2 text-lg font-medium text-n-slate-12">
          {{ t('CRM_KANBAN.EMPTY.TITLE') }}
        </p>
        <p class="mb-5 text-sm leading-6 text-n-slate-11">
          {{ t('CRM_KANBAN.EMPTY.DESCRIPTION') }}
        </p>
        <Button
          v-if="canManagePipelines"
          :label="t('CRM_KANBAN.ACTIONS.CREATE_INITIAL_PIPELINE')"
          icon="i-lucide-kanban"
          @click="openCreatePipelineDrawer"
        />
      </div>
    </section>

    <section
      v-else-if="viewMode === 'kanban'"
      class="flex flex-1 gap-4 overflow-x-auto overflow-y-hidden bg-n-slate-3 px-8 py-5"
    >
      <article
        v-for="stage in stages"
        :key="stage.id"
        class="flex h-full w-[19rem] shrink-0 flex-col overflow-hidden rounded-lg border border-n-weak bg-n-surface-2 shadow-sm"
      >
        <header class="border-b border-n-weak px-4 py-3">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <div class="flex items-center gap-2">
                <span
                  class="h-2.5 w-2.5 shrink-0 rounded-sm"
                  :style="{ backgroundColor: stage.color || '#64748b' }"
                />
                <h2 class="mb-0 truncate text-sm font-medium text-n-slate-12">
                  {{ stage.name }}
                </h2>
              </div>
              <p class="mt-1 mb-0 text-xs text-n-slate-11">
                {{
                  t('CRM_KANBAN.STATUS.STAGE_CARDS', {
                    count: stage.cards_count ?? stage.cards.length,
                  })
                }}
              </p>
            </div>
            <span
              v-if="stage.wip_limit"
              class="rounded-md bg-n-alpha-2 px-2 py-1 text-[11px] text-n-slate-11"
            >
              {{ t('CRM_KANBAN.STATUS.WIP', { count: stage.wip_limit }) }}
            </span>
          </div>
        </header>

        <!-- :sort=false — a ordem da coluna é sempre por conversa mais recente
             (getter); reordenar manualmente dentro da coluna seria revertido no
             próximo tick, então fica desabilitado. Drag entre etapas segue. -->
        <Draggable
          v-model="stage.cards"
          item-key="id"
          group="crm-kanban-cards"
          ghost-class="opacity-40"
          drag-class="cursor-grabbing"
          class="flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto p-3"
          :animation="150"
          :disabled="!canMoveCards"
          :sort="false"
          @start="onDragStart"
          @change="event => onDragChange(stage, event)"
        >
          <template #item="{ element }">
            <CrmKanbanCard
              :card="element"
              :stage-color="stage.color"
              @open="openCardDrawer"
            />
          </template>

          <template #footer>
            <div
              v-if="stage.cards.length === 0"
              class="flex min-h-24 items-center justify-center rounded-lg border border-dashed border-n-weak px-4 py-6 text-center text-xs leading-5 text-n-slate-10"
            >
              {{ t('CRM_KANBAN.EMPTY.DROP_HINT') }}
            </div>
            <Button
              v-if="stage.has_more"
              :label="t('CRM_KANBAN.ACTIONS.LOAD_MORE')"
              icon="i-lucide-chevron-down"
              slate
              faded
              sm
              @click="loadMore(stage)"
            />
          </template>
        </Draggable>
      </article>
    </section>

    <section
      v-else-if="viewMode === 'list'"
      class="flex min-h-0 flex-1 flex-col px-8 py-5"
    >
      <div class="mb-3 flex items-center justify-between gap-2">
        <div class="flex items-center gap-3">
          <CrmResultTabs
            :model-value="filters.result"
            @update:model-value="selectResult"
          />
          <p class="mb-0 text-xs text-n-slate-10">
            {{ t('CRM_KANBAN.LIST.META', { count: cardsListMeta.count || 0 }) }}
          </p>
        </div>
        <div class="flex items-center gap-2">
          <CrmSavedViews
            :views="savedViews"
            :current-config="currentSavedViewConfig"
            :pipeline-id="currentPipelineId"
            @apply="onSavedViewApply"
            @create="onSavedViewCreate"
            @update="onSavedViewUpdate"
            @delete="onSavedViewDelete"
          />
          <CrmTableColumnSettings
            :columns="columnSettingsItems"
            :density="listColumnState.density"
            @update="onColumnSettingsUpdate"
          />
        </div>
      </div>
      <CrmCardsTable
        :cards="cardsList"
        :stages="stages"
        :owners="agents"
        :loading="uiFlags.isFetchingCardsList"
        :error="!!loadError"
        :sort="listSort"
        :group-by="listGroupBy"
        :column-state="listColumnState"
        :selected-ids="listSelection"
        :collapsed-groups="collapsedGroups"
        :total-count="cardsListMeta.count || 0"
        :has-more="hasMoreCards"
        :has-active-filters="hasActiveFilters"
        @sort-change="onListSortChange"
        @page-change="loadMoreList"
        @group-change="onListGroupChange"
        @column-change="onListColumnChange"
        @select-change="onListSelectChange"
        @open-card="openCardDrawer"
        @edit-save="onListEditSave"
        @retry="loadCurrentList"
        @clear-filters="clearFilters"
      />
      <CrmBulkActionBar
        :count="listSelection.length"
        :stages="stages"
        :owners="agents"
        :is-busy="uiFlags.isBulkActing"
        @move="onBulkMove"
        @assign="onBulkAssign"
        @status="onBulkStatus"
        @archive="onBulkArchive"
        @clear="onBulkClear"
      />
    </section>

    <section
      v-else-if="viewMode === 'calendar'"
      class="flex min-h-0 flex-1 flex-col px-8 pb-4 pt-1"
    >
      <CrmCalendar
        :events="calendarEvents"
        :loading="uiFlags.isFetchingCalendar"
        :error="!!loadError"
        :owners="agents"
        :current-user-id="currentUser?.id"
        :pipeline-id="currentPipelineId"
        :pipelines="pipelineOptions"
        :paused="
          showDrawer ||
          showPipelineDrawer ||
          showInboxSettingsDrawer ||
          showBookingProfilesDrawer
        "
        @update:pipeline-id="currentPipelineId = $event"
        @range-change="onCalendarRangeChange"
        @view-change="onCalendarViewChange"
        @open-event="onCalendarOpenEvent"
        @quick-add="onCalendarQuickAdd"
        @reschedule="onCalendarReschedule"
        @retry="loadCurrentCalendar"
      />
    </section>

    <CrmCalendarQuickAdd
      :show="showQuickAdd"
      :date="quickAddDate"
      :pipeline-id="currentPipelineId"
      :default-type="quickAddType"
      :meetings-enabled="isMeetingFeatureEnabled"
      @create="onQuickAddCreate"
      @more-options="onQuickAddMoreOptions"
      @schedule-meeting="onQuickAddScheduleMeeting"
      @close="showQuickAdd = false"
    />

    <CrmCalendarMeetingScheduler
      v-if="isMeetingFeatureEnabled"
      v-model:show="showMeetingScheduler"
      :account-id="currentAccountId"
      :card-id="meetingSchedulerCard?.id"
      :deal-title="meetingSchedulerCard?.title"
      :date="meetingSchedulerDate"
      :available-inboxes="inboxes"
      :card-contact-email="meetingSchedulerCard?.contact?.email"
      :card-contact-name="meetingSchedulerCard?.contact?.name"
      :meeting="meetingSchedulerMeeting"
      @create="scheduleMeeting"
      @updated="onMeetingRescheduled"
      @close="closeMeetingScheduler"
    />

    <CrmMeetingDetail
      :show="showMeetingDetail"
      :event="selectedMeetingEvent"
      :account-id="currentAccountId"
      :timezone="userTimezone"
      @close="closeMeetingDetail"
      @open-card="onMeetingOpenCard"
      @reschedule="onMeetingReschedule"
      @canceled="onMeetingCanceled"
      @updated="onMeetingUpdated"
    />

    <CrmCardDrawer
      ref="cardDrawerRef"
      :show="showDrawer"
      :mode="drawerMode"
      :card="selectedCard"
      :initial-tab="drawerInitialTab"
      :stages="stages"
      :pipeline-id="currentPipelineId"
      :agents="agents"
      :inboxes="inboxes"
      :follow-ups="followUps"
      :can-manage-cards="canManageCards"
      :can-manage-ai="canManageAi"
      :is-saving="uiFlags.isCreatingCard || uiFlags.isUpdatingCard"
      :is-loading-details="uiFlags.isFetchingCard"
      :is-archiving="uiFlags.isArchivingCard"
      :is-fetching-follow-ups="uiFlags.isFetchingFollowUps"
      :is-saving-follow-up="uiFlags.isSavingFollowUp"
      :meetings-enabled="isMeetingFeatureEnabled"
      @save="saveCard"
      @schedule-meeting="onDrawerScheduleMeeting"
      @archive="archiveCard"
      @close-deal="closeCardDeal"
      @create-follow-up="createFollowUp"
      @complete-follow-up="completeFollowUp"
      @cancel-follow-up="cancelFollowUp"
      @refresh-card="refreshSelectedCard"
      @close="closeDrawer"
    />

    <CrmPipelineDrawer
      :show="showPipelineDrawer"
      :mode="pipelineDrawerMode"
      :pipeline="pipelineDrawerMode === 'edit' ? selectedPipeline : null"
      :stages="pipelineDrawerMode === 'edit' ? stages : []"
      :inboxes="inboxes"
      :pipeline-inboxes="pipelineInboxes"
      :is-saving="uiFlags.isSavingPipeline"
      :is-archiving="uiFlags.isArchivingPipeline"
      :is-deleting-stage="uiFlags.isDeletingStage"
      :is-loading-pipeline-inboxes="uiFlags.isFetchingPipelineInboxes"
      :is-saving-pipeline-inbox="uiFlags.isSavingPipelineInbox"
      :is-removing-pipeline-inbox="uiFlags.isRemovingPipelineInbox"
      :agents="agents"
      @save="savePipeline"
      @archive="archivePipeline"
      @delete-stage="deleteStage"
      @add-pipeline-inbox="addPipelineInbox"
      @remove-pipeline-inbox="removePipelineInbox"
      @close="closePipelineDrawer"
    />

    <CrmInboxSettingsDrawer
      :show="showInboxSettingsDrawer"
      :inboxes="inboxes"
      :settings="inboxSettings"
      :pipelines="pipelines"
      :stages-by-pipeline="inboxSettingStagesByPipeline"
      :is-loading="uiFlags.isFetchingInboxSettings"
      :is-saving="uiFlags.isSavingInboxSetting"
      :is-loading-stages="uiFlags.isFetchingPipelineStages"
      @save="saveInboxSetting"
      @load-pipeline-stages="loadPipelineStagesForSettings"
      @close="closeInboxSettingsDrawer"
    />

    <CrmBookingProfilesDrawer
      :show="showBookingProfilesDrawer"
      :inboxes="inboxes"
      :pipelines="pipelines"
      :agents="agents"
      @close="closeBookingProfilesDrawer"
    />

    <ConfirmModal
      ref="confirmModal"
      :title="confirmConfig.title"
      :description="confirmConfig.description"
      :confirm-label="confirmConfig.confirmLabel"
      :cancel-label="t('CRM_KANBAN.CONFIRM.CANCEL')"
    />
  </main>
</template>
