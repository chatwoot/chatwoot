<script setup>
import { ref, unref, provide, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import {
  useMapGetter,
  useFunctionGetter,
} from 'dashboard/composables/store.js';

import ChatListHeader from './ChatListHeader.vue';
import ConversationList from './ConversationList.vue';
import ConversationExportDialog from './ConversationExportDialog.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ConversationFilter from 'next/filter/ConversationFilter.vue';
import ConversationAPI from 'dashboard/api/inbox/conversation';
import SaveCustomView from 'next/filter/SaveCustomView.vue';
import ChatTypeTabs from './widgets/ChatTypeTabs.vue';
import DeleteCustomViews from 'dashboard/routes/dashboard/customviews/DeleteCustomViews.vue';
import ConversationBulkActions from './widgets/conversation/conversationBulkActions/Index.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';

import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useBulkActions } from 'dashboard/composables/chatlist/useBulkActions';
import { useFilter } from 'shared/composables/useFilter';
import { useTrack } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import {
  useCamelCase,
  useSnakeCase,
} from 'dashboard/composables/useTransformKeys';
import { useEmitter } from 'dashboard/composables/emitter';
import { useBusinessRulesStatusGuard } from 'dashboard/composables/useBusinessRulesStatusGuard';

import { emitter } from 'shared/helpers/mitt';

import wootConstants from 'dashboard/constants/globals';
import advancedFilterOptions from './widgets/conversation/advancedFilterItems';
import filterQueryGenerator from '../helper/filterQueryGenerator.js';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries';
import { generateValuesForEditCustomViews } from 'dashboard/helper/customViewsHelper';
import { useStatusLabel } from 'dashboard/composables/useStatusLabel';
import { conversationListPageURL } from '../helper/URLHelper';
import {
  isOnMentionsView,
  isOnParticipatingView,
  isOnUnattendedView,
} from '../store/modules/conversations/helpers/actionHelpers';
import {
  getUserPermissions,
  filterItemsByPermission,
} from 'dashboard/helper/permissionsHelper.js';
import { matchesFilters } from '../store/modules/conversations/helpers/filterHelpers';
import {
  matchesUnassignedTab,
  isValidConversationSortKey,
} from '../store/modules/conversations/helpers';
import {
  getInboxBotAgent,
  isCurrentUserAssigneeMeta,
} from 'dashboard/helper/assigneeHelper';
import { CONVERSATION_EVENTS } from '../helper/AnalyticsHelper/events';
import { ASSIGNEE_TYPE_TAB_PERMISSIONS } from 'dashboard/constants/permissions.js';

const props = defineProps({
  conversationInbox: { type: [String, Number], default: 0 },
  teamId: { type: [String, Number], default: 0 },
  label: { type: String, default: '' },
  conversationType: { type: String, default: '' },
  foldersId: { type: [String, Number], default: 0 },
  showConversationList: { default: true, type: Boolean },
  isOnExpandedLayout: { default: false, type: Boolean },
});

const emit = defineEmits(['conversationLoad']);
const { uiSettings } = useUISettings();
const { t } = useI18n();
const { getStatusLabel } = useStatusLabel();
const router = useRouter();
const route = useRoute();
const store = useStore();

const resolveAttributesModalRef = ref(null);

const activeAssigneeTab = ref(wootConstants.ASSIGNEE_TYPE.ME);
const autoSwitchedToUnassigned = ref(false);
const autoSwitchedStatusToAll = ref(false);
const previousStatusBeforeBotSwitch = ref(null);
const activeStatus = ref(wootConstants.STATUS_TYPE.OPEN);
const activeSortBy = ref(wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC);
const showAdvancedFilters = ref(false);
// chatsOnView is to store the chats that are currently visible on the screen,
// which mirrors the conversationList.
const chatsOnView = ref([]);
const foldersQuery = ref({});
const showAddFoldersModal = ref(false);
const showDeleteFoldersModal = ref(false);
const appliedFilter = ref([]);
const advancedFilterTypes = ref(
  advancedFilterOptions.map(filter => ({
    ...filter,
    attributeName: t(`FILTER.ATTRIBUTES.${filter.attributeI18nKey}`),
  }))
);

const currentUser = useMapGetter('getCurrentUser');
const chatLists = useMapGetter('getFilteredConversations');
const mineChatsList = useMapGetter('getMineChats');
const allChatList = useMapGetter('getAllStatusChats');
const unAssignedChatsList = useMapGetter('getUnAssignedChats');
const participatingChatsList = useMapGetter('getParticipatingChats');
const chatListLoading = useMapGetter('getChatListLoadingStatus');
const activeInbox = useMapGetter('getSelectedInbox');
const conversationStats = useMapGetter('conversationStats/getStats');
const appliedFilters = useMapGetter('getAppliedConversationFiltersV2');
const appliedFiltersForExport = useMapGetter('getAppliedConversationFilters');
const folders = useMapGetter('customViews/getConversationCustomViews');
const conversationExportDialogRef = ref(null);
const isExportingConversations = ref(false);
const agentList = useMapGetter('agents/getAgents');
const teamsList = useMapGetter('teams/getTeams');
const inboxesList = useMapGetter('inboxes/getInboxes');
const campaigns = useMapGetter('campaigns/getAllCampaigns');
const labels = useMapGetter('labels/getLabels');
const currentAccountId = useMapGetter('getCurrentAccountId');
// We can't useFunctionGetter here since it needs to be called on setup?
const getAssignableAgents = useMapGetter(
  'inboxAssignableAgents/getAssignableAgents'
);
const getTeamFn = useMapGetter('teams/getTeam');
const getConversationById = useMapGetter('getConversationById');

const {
  selectedConversations,
  selectedInboxes,
  selectConversation,
  deSelectConversation,
  selectAllConversations,
  resetBulkActions,
  isConversationSelected,
  onAssignAgent,
  onAssignLabels,
  onRemoveLabels,
} = useBulkActions();

const {
  initializeStatusAndAssigneeFilterToModal,
  initializeInboxTeamAndLabelFilterToModal,
} = useFilter({
  filteri18nKey: 'FILTER',
  attributeModel: 'conversation_attribute',
});

const { checkStatusChange } = useBusinessRulesStatusGuard();

// computed

const hasAppliedFilters = computed(() => {
  return appliedFilters.value.length !== 0;
});

const activeFolder = computed(() => {
  if (props.foldersId) {
    const activeView = folders.value.filter(
      view => view.id === Number(props.foldersId)
    );
    const [firstValue] = activeView;
    return firstValue;
  }
  return undefined;
});

const getContact = useMapGetter('contacts/getContact');
const folderContactId = useMapGetter('customViews/getActiveFolderContactId');

const activeFolderName = computed(() => {
  return activeFolder.value?.name;
});

const hasActiveFolders = computed(() => {
  return Boolean(activeFolder.value && props.foldersId !== 0);
});

const hasAppliedFiltersOrActiveFolders = computed(() => {
  return hasAppliedFilters.value || hasActiveFolders.value;
});

const currentUserDetails = computed(() => {
  const { id, name } = currentUser.value;
  return { id, name };
});

const userPermissions = computed(() => {
  return getUserPermissions(currentUser.value, currentAccountId.value);
});

const activeInboxId = computed(() => {
  if (props.conversationInbox) return props.conversationInbox;
  if (route.params.inbox_id) return route.params.inbox_id;
  return activeInbox.value;
});

const inboxBot = computed(() => {
  const inboxId = activeInboxId.value;
  if (!inboxId) return null;
  const agents = getAssignableAgents.value(inboxId) || [];
  return getInboxBotAgent(agents);
});

const assigneeTabItems = computed(() => {
  return filterItemsByPermission(
    ASSIGNEE_TYPE_TAB_PERMISSIONS,
    userPermissions.value,
    item => item.permissions
  ).map(({ key, count: countKey }) => {
    let name = t(`CHAT_LIST.ASSIGNEE_TYPE_TABS.${key}`);
    if (key === 'unassigned' && inboxBot.value?.name) {
      name = inboxBot.value.name;
    }
    return {
      key,
      name,
      count: conversationStats.value[countKey] || 0,
    };
  });
});

const showAssigneeInConversationCard = computed(() => {
  return (
    hasAppliedFiltersOrActiveFolders.value ||
    activeAssigneeTab.value === wootConstants.ASSIGNEE_TYPE.ALL
  );
});

const currentPageFilterKey = computed(() => {
  return hasAppliedFiltersOrActiveFolders.value
    ? 'appliedFilters'
    : activeAssigneeTab.value;
});

const inbox = useFunctionGetter('inboxes/getInbox', activeInbox);
const currentPage = useFunctionGetter(
  'conversationPage/getCurrentPageFilter',
  activeAssigneeTab
);
const currentFiltersPage = useFunctionGetter(
  'conversationPage/getCurrentPageFilter',
  currentPageFilterKey
);
const hasCurrentPageEndReached = useFunctionGetter(
  'conversationPage/getHasEndReached',
  currentPageFilterKey
);

const conversationCustomAttributes = useFunctionGetter(
  'attributes/getAttributesByModel',
  'conversation_attribute'
);

const activeAssigneeTabCount = computed(() => {
  const count = assigneeTabItems.value.find(
    item => item.key === activeAssigneeTab.value
  ).count;
  return count;
});

const conversationListPagination = computed(() => {
  const conversationsPerPage = 25;
  const hasChatsOnView =
    chatsOnView.value &&
    Array.isArray(chatsOnView.value) &&
    !chatsOnView.value.length;
  const isNoFiltersOrFoldersAndChatListNotEmpty =
    !hasAppliedFiltersOrActiveFolders.value && hasChatsOnView;
  const isUnderPerPage =
    chatsOnView.value.length < conversationsPerPage &&
    activeAssigneeTabCount.value < conversationsPerPage &&
    activeAssigneeTabCount.value > chatsOnView.value.length;

  if (isNoFiltersOrFoldersAndChatListNotEmpty && isUnderPerPage) {
    return 1;
  }

  return currentPage.value + 1;
});

const conversationFilters = computed(() => {
  return {
    inboxId: activeInboxId.value || undefined,
    assigneeType: activeAssigneeTab.value,
    status: activeStatus.value,
    sortBy: activeSortBy.value,
    page: conversationListPagination.value,
    labels: props.label ? [props.label] : undefined,
    teamId: props.teamId || undefined,
    conversationType: props.conversationType || undefined,
  };
});

// Snake_case list params for export — same fields ConversationFinder / index API use
const listFiltersForExport = computed(() => {
  const filters = conversationFilters.value;
  return {
    inbox_id: filters.inboxId,
    status: filters.status,
    assignee_type: filters.assigneeType,
    team_id: filters.teamId,
    labels: filters.labels,
    conversation_type: filters.conversationType,
  };
});

const activeTeam = computed(() => {
  if (props.teamId) {
    return getTeamFn.value(props.teamId);
  }
  return {};
});

const pageTitle = computed(() => {
  if (hasAppliedFilters.value) {
    return t('CHAT_LIST.TAB_HEADING');
  }
  if (inbox.value.name) {
    return inbox.value.name;
  }
  if (activeTeam.value.name) {
    return activeTeam.value.name;
  }
  if (props.label) {
    return `#${props.label}`;
  }
  if (props.conversationType === wootConstants.CONVERSATION_TYPE.MENTION) {
    return t('CHAT_LIST.MENTION_HEADING');
  }
  if (
    props.conversationType === wootConstants.CONVERSATION_TYPE.PARTICIPATING
  ) {
    return t('CONVERSATION_PARTICIPANTS.SIDEBAR_MENU_TITLE');
  }
  if (props.conversationType === wootConstants.CONVERSATION_TYPE.UNATTENDED) {
    return t('CHAT_LIST.UNATTENDED_HEADING');
  }
  if (hasActiveFolders.value) {
    return activeFolder.value.name;
  }
  return t('CHAT_LIST.TAB_HEADING');
});

function filterByAssigneeTab(conversations) {
  if (activeAssigneeTab.value === wootConstants.ASSIGNEE_TYPE.ME) {
    return conversations.filter(c =>
      isCurrentUserAssigneeMeta(c.meta, currentUser.value)
    );
  }
  if (activeAssigneeTab.value === wootConstants.ASSIGNEE_TYPE.UNASSIGNED) {
    const inboxBotId = inboxBot.value?.id;
    return conversations.filter(c => matchesUnassignedTab(c, { inboxBotId }));
  }
  return [...conversations];
}

function sortByUnreadStatus(conversations) {
  return [...conversations].sort((a, b) => {
    const unreadCountDiff = (b.unread_count || 0) - (a.unread_count || 0);
    if (unreadCountDiff !== 0) return unreadCountDiff;

    return (b.last_activity_at || 0) - (a.last_activity_at || 0);
  });
}

const conversationList = computed(() => {
  let localConversationList = [];

  if (!hasAppliedFiltersOrActiveFolders.value) {
    const filters = conversationFilters.value;
    if (
      props.conversationType === wootConstants.CONVERSATION_TYPE.PARTICIPATING
    ) {
      localConversationList = filterByAssigneeTab(
        participatingChatsList.value(filters)
      );
    } else if (activeAssigneeTab.value === 'me') {
      localConversationList = [...mineChatsList.value(filters)];
    } else if (activeAssigneeTab.value === 'unassigned') {
      localConversationList = [...unAssignedChatsList.value(filters)];
    } else {
      localConversationList = [...allChatList.value(filters)];
    }
  } else {
    localConversationList = [...chatLists.value];
  }

  if (activeFolder.value) {
    const { payload } = activeFolder.value.query;
    localConversationList = localConversationList.filter(conversation => {
      return matchesFilters(conversation, payload);
    });
  }

  if (
    !hasAppliedFiltersOrActiveFolders.value &&
    activeSortBy.value === wootConstants.SORT_BY_TYPE.UNREAD
  ) {
    localConversationList = sortByUnreadStatus(localConversationList);
  }

  return localConversationList;
});

const showEndOfListMessage = computed(() => {
  return !!(
    conversationList.value.length &&
    hasCurrentPageEndReached.value &&
    !chatListLoading.value
  );
});

const allConversationsSelected = computed(() => {
  return (
    conversationList.value.length === selectedConversations.value.length &&
    conversationList.value.every(el =>
      selectedConversations.value.includes(el.id)
    )
  );
});

const uniqueInboxes = computed(() => {
  return [...new Set(selectedInboxes.value)];
});

// ---------------------- Methods -----------------------
function setFiltersFromUISettings() {
  const { conversations_filter_by: filterBy = {} } = uiSettings.value;
  const { status, order_by: orderBy } = filterBy;
  activeStatus.value = status || wootConstants.STATUS_TYPE.OPEN;
  activeSortBy.value = isValidConversationSortKey(orderBy)
    ? orderBy
    : wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC;
}

function emitConversationLoaded() {
  emit('conversationLoad');
}

function fetchFilteredConversations(payload) {
  payload = useSnakeCase(payload);
  let page = currentFiltersPage.value + 1;
  store
    .dispatch('fetchFilteredConversations', {
      queryData: filterQueryGenerator(payload),
      page,
    })
    .catch(() => useAlert(t('CHAT_LIST.FETCH_ERROR')))
    // emit even on failure so a deep-linked conversation still loads via
    // fetchConversationIfUnavailable
    .finally(emitConversationLoaded);

  showAdvancedFilters.value = false;
}

function fetchSavedFilteredConversations(payload) {
  payload = useSnakeCase(payload);
  let page = currentFiltersPage.value + 1;
  store
    .dispatch('fetchFilteredConversations', {
      queryData: payload,
      page,
    })
    .catch(() => useAlert(t('CHAT_LIST.FETCH_ERROR')))
    .finally(emitConversationLoaded);
}

function onApplyFilter(payload) {
  payload = useSnakeCase(payload);
  resetBulkActions();
  foldersQuery.value = filterQueryGenerator(payload);
  store.dispatch('conversationPage/reset');
  store.dispatch('emptyAllConversations');
  fetchFilteredConversations(payload);
}

function closeAdvanceFiltersModal() {
  showAdvancedFilters.value = false;
  appliedFilter.value = [];
}

function onUpdateSavedFilter(payload, folderName) {
  const transformedPayload = useSnakeCase(payload);
  const payloadData = {
    ...unref(activeFolder),
    name: unref(folderName),
    query: filterQueryGenerator(transformedPayload),
  };
  store.dispatch('customViews/update', payloadData);
  closeAdvanceFiltersModal();
}

function onClickOpenAddFoldersModal() {
  showAddFoldersModal.value = true;
}

function onCloseAddFoldersModal() {
  showAddFoldersModal.value = false;
}

function onClickOpenDeleteFoldersModal() {
  showDeleteFoldersModal.value = true;
}

function onCloseDeleteFoldersModal() {
  showDeleteFoldersModal.value = false;
}

function setParamsForEditFolderModal() {
  // Here we are setting the params for edit folder modal to show the existing values.

  // For agent, team, inboxes,and campaigns we get only the id's from the query.
  // So we are mapping the id's to the actual values.

  // For labels we get the name of the label from the query.
  // If we delete the label from the label list then we will not be able to show the label name.

  // For custom attributes we get only attribute key.
  // So we are mapping it to find the input type of the attribute to show in the edit folder modal.
  return {
    agents: agentList.value,
    teams: teamsList.value,
    inboxes: inboxesList.value,
    labels: labels.value,
    campaigns: campaigns.value,
    contacts: [getContact.value(folderContactId.value)],
    languages: languages,
    countries: countries,
    priority: [
      { id: 'low', name: t('CONVERSATION.PRIORITY.OPTIONS.LOW') },
      { id: 'medium', name: t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM') },
      { id: 'high', name: t('CONVERSATION.PRIORITY.OPTIONS.HIGH') },
      { id: 'urgent', name: t('CONVERSATION.PRIORITY.OPTIONS.URGENT') },
    ],
    filterTypes: advancedFilterTypes.value,
    allCustomAttributes: conversationCustomAttributes.value,
    statusLabelFn: getStatusLabel,
  };
}

function initializeExistingFilterToModal() {
  const statusFilter = initializeStatusAndAssigneeFilterToModal(
    activeStatus.value,
    currentUserDetails.value,
    activeAssigneeTab.value
  );
  // TODO: Remove the usage of useCamelCase after migrating useFilter to camelcase
  if (statusFilter) {
    appliedFilter.value = [...appliedFilter.value, useCamelCase(statusFilter)];
  }

  // TODO: Remove the usage of useCamelCase after migrating useFilter to camelcase
  const otherFilters = initializeInboxTeamAndLabelFilterToModal(
    props.conversationInbox,
    inbox.value,
    props.teamId,
    activeTeam.value,
    props.label
  ).map(useCamelCase);

  appliedFilter.value = [...appliedFilter.value, ...otherFilters];
}

function initializeFolderToFilterModal(newActiveFolder) {
  // Here we are setting the params for edit folder modal.
  //  To show the existing values. when we click on edit folder button.

  // Here we get the query from the active folder.
  // And we are mapping the query to the actual values.
  // To show in the edit folder modal by the help of generateValuesForEditCustomViews helper.
  const query = unref(newActiveFolder)?.query?.payload;
  if (!Array.isArray(query)) return;

  const newFilters = query.map(filter => {
    const transformed = useCamelCase(filter);
    const values = Array.isArray(transformed.values)
      ? generateValuesForEditCustomViews(
          useSnakeCase(filter),
          setParamsForEditFolderModal()
        )
      : [];

    return {
      attributeKey: transformed.attributeKey,
      attributeModel: transformed.attributeModel,
      customAttributeType: transformed.customAttributeType,
      filterOperator: transformed.filterOperator,
      queryOperator: transformed.queryOperator ?? 'and',
      values,
    };
  });

  appliedFilter.value = [...appliedFilter.value, ...newFilters];
}

function initalizeAppliedFiltersToModal() {
  appliedFilter.value = [...appliedFilters.value];
}

function onToggleAdvanceFiltersModal() {
  if (showAdvancedFilters.value === true) {
    closeAdvanceFiltersModal();
    return;
  }

  if (!hasAppliedFilters.value && !hasActiveFolders.value) {
    initializeExistingFilterToModal();
  }
  if (hasActiveFolders.value) {
    initializeFolderToFilterModal(activeFolder.value);
  }
  if (hasAppliedFilters.value) {
    initalizeAppliedFiltersToModal();
  }

  showAdvancedFilters.value = true;
}

const openConversationExportDialog = () => {
  conversationExportDialogRef.value?.dialogRef.open();
};

const onExportConversations = async query => {
  isExportingConversations.value = true;
  try {
    await ConversationAPI.exportConversations(query);
    useAlert(t('CHAT_LIST.EXPORT_CONVERSATION.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error.message || t('CHAT_LIST.EXPORT_CONVERSATION.ERROR_MESSAGE'));
  } finally {
    isExportingConversations.value = false;
  }
};

function fetchConversations() {
  store.dispatch('updateChatListFilters', conversationFilters.value);
  store.dispatch('fetchAllConversations').then(emitConversationLoaded);
}

function resetAndFetchData() {
  appliedFilter.value = [];
  resetBulkActions();
  store.dispatch('conversationPage/reset');
  store.dispatch('emptyAllConversations');
  store.dispatch('clearConversationFilters');
  if (hasActiveFolders.value) {
    const payload = activeFolder.value.query;
    fetchSavedFilteredConversations(payload);
  }
  if (props.foldersId) {
    return;
  }
  fetchConversations();
}

function loadMoreConversations() {
  if (hasCurrentPageEndReached.value || chatListLoading.value) {
    return;
  }

  if (!hasAppliedFiltersOrActiveFolders.value) {
    fetchConversations();
  } else if (hasActiveFolders.value) {
    const payload = activeFolder.value.query;
    fetchSavedFilteredConversations(payload);
  } else if (hasAppliedFilters.value) {
    fetchFilteredConversations(appliedFilters.value);
  }
}

function updateAssigneeTab(selectedTab) {
  if (activeAssigneeTab.value !== selectedTab) {
    resetBulkActions();
    emitter.emit('clearSearchInput');
    activeAssigneeTab.value = selectedTab;
    autoSwitchedToUnassigned.value = false;
    if (!currentPage.value) {
      fetchConversations();
    }
  }
}

function onBasicFilterChange(value, type) {
  if (type === 'status') {
    activeStatus.value = value;
    autoSwitchedStatusToAll.value = false;
    previousStatusBeforeBotSwitch.value = null;
  } else {
    activeSortBy.value = value;
  }
  resetAndFetchData();
}

function openLastSavedItemInFolder() {
  const lastItemOfFolder = folders.value[folders.value.length - 1];
  const lastItemId = lastItemOfFolder.id;
  router.push({
    name: 'folder_conversations',
    params: { id: lastItemId },
  });
}

function openLastItemAfterDeleteInFolder() {
  if (folders.value.length > 0) {
    openLastSavedItemInFolder();
  } else {
    router.push({ name: 'home' });
    fetchConversations();
  }
}

function redirectToConversationList() {
  const {
    params: { accountId, inbox_id: inboxId, label, teamId },
    name,
  } = route;

  let conversationType = '';
  if (isOnMentionsView({ route: { name } })) {
    conversationType = wootConstants.CONVERSATION_TYPE.MENTION;
  } else if (isOnParticipatingView({ route: { name } })) {
    conversationType = wootConstants.CONVERSATION_TYPE.PARTICIPATING;
  } else if (isOnUnattendedView({ route: { name } })) {
    conversationType = wootConstants.CONVERSATION_TYPE.UNATTENDED;
  }
  router.push(
    conversationListPageURL({
      accountId,
      conversationType: conversationType,
      customViewId: props.foldersId,
      inboxId,
      label,
      teamId,
    })
  );
}

async function assignPriority(priority, conversationId = null) {
  store.dispatch('setCurrentChatPriority', {
    priority,
    conversationId,
  });
  store.dispatch('assignPriority', { conversationId, priority }).then(() => {
    useTrack(CONVERSATION_EVENTS.CHANGE_PRIORITY, {
      newValue: priority,
      from: 'Context menu',
    });
    useAlert(
      t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SUCCESSFUL', {
        priority,
        conversationId,
      })
    );
  });
}

async function markAsUnread(conversationId) {
  try {
    await store.dispatch('markMessagesUnread', {
      id: conversationId,
    });
    redirectToConversationList();
  } catch (error) {
    // Ignore error
  }
}
async function markAsRead(conversationId) {
  try {
    await store.dispatch('markMessagesRead', {
      id: conversationId,
    });
  } catch (error) {
    // Ignore error
  }
}

async function onAssignTeam(team, conversationId = null) {
  try {
    await store.dispatch('assignTeam', {
      conversationId,
      teamId: team.id,
    });
    useAlert(
      t('CONVERSATION.CARD_CONTEXT_MENU.API.TEAM_ASSIGNMENT.SUCCESFUL', {
        team: team.name,
        conversationId,
      })
    );
  } catch (error) {
    useAlert(t('CONVERSATION.CARD_CONTEXT_MENU.API.TEAM_ASSIGNMENT.FAILED'));
  }
}

function toggleConversationStatus(
  conversationId,
  status,
  snoozedUntil,
  customAttributes = null
) {
  const payload = {
    conversationId,
    status,
    snoozedUntil,
  };

  if (customAttributes) {
    payload.customAttributes = customAttributes;
  }

  store.dispatch('toggleStatus', payload).then(() => {
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  });
}

function handleResolveConversation(conversationId, status, snoozedUntil) {
  if (status !== wootConstants.STATUS_TYPE.RESOLVED) {
    toggleConversationStatus(conversationId, status, snoozedUntil);
    return;
  }

  const conversation = getConversationById.value(conversationId);
  const guard = checkStatusChange(conversation, status);
  if (guard.forbiddenLabels?.length || guard.needsAssignee) {
    return;
  }

  if (guard.missingAttributes?.length) {
    resolveAttributesModalRef.value?.open(
      guard.requiredAttributes?.length
        ? guard.requiredAttributes
        : guard.missingAttributes,
      conversation?.custom_attributes || {},
      { id: conversationId, snoozedUntil, status, conversation },
      conversation?.meta?.sender?.custom_attributes || {}
    );
  } else {
    toggleConversationStatus(conversationId, status, snoozedUntil);
  }
}

function handleResolveWithAttributes({
  attributes,
  contactAttributes = {},
  context,
}) {
  if (!context) return;

  const existingConversation = getConversationById.value(context.id);
  const contactId = existingConversation?.meta?.sender?.id;
  const runToggle = () => {
    const currentCustomAttributes =
      existingConversation?.custom_attributes || {};
    const mergedAttributes = { ...currentCustomAttributes, ...attributes };
    toggleConversationStatus(
      context.id,
      context.status || wootConstants.STATUS_TYPE.RESOLVED,
      context.snoozedUntil,
      mergedAttributes
    );
  };

  if (contactId && Object.keys(contactAttributes || {}).length) {
    store
      .dispatch('contacts/update', {
        id: contactId,
        customAttributes: {
          ...(existingConversation?.meta?.sender?.custom_attributes || {}),
          ...contactAttributes,
        },
      })
      .then(runToggle)
      .catch(() => {});
    return;
  }

  runToggle();
}

function allSelectedConversationsStatus(status) {
  if (!selectedConversations.value.length) return false;
  return selectedConversations.value.every(item => {
    return getConversationById.value(item)?.status === status;
  });
}

function toggleSelectAll(check) {
  selectAllConversations(check, conversationList);
}

useEmitter('fetch_conversation_stats', () => {
  if (hasAppliedFiltersOrActiveFolders.value) return;
  store.dispatch('conversationStats/get', conversationFilters.value);
});

function applyBotInboxViewDefaults({ skipFetch = false } = {}) {
  if (!inboxBot.value) return false;

  let changed = false;
  if (activeAssigneeTab.value === wootConstants.ASSIGNEE_TYPE.ME) {
    activeAssigneeTab.value = wootConstants.ASSIGNEE_TYPE.UNASSIGNED;
    autoSwitchedToUnassigned.value = true;
    changed = true;
  }
  if (activeStatus.value === wootConstants.STATUS_TYPE.PENDING) {
    previousStatusBeforeBotSwitch.value = activeStatus.value;
    activeStatus.value = wootConstants.STATUS_TYPE.ALL;
    autoSwitchedStatusToAll.value = true;
    changed = true;
  }
  if (changed) {
    store.dispatch('setChatStatusFilter', activeStatus.value);
    if (!skipFetch) {
      resetAndFetchData();
    }
  }
  return changed;
}

function restoreBotInboxViewDefaults({ skipFetch = false } = {}) {
  if (inboxBot.value) return false;

  let changed = false;
  if (
    autoSwitchedToUnassigned.value &&
    activeAssigneeTab.value === wootConstants.ASSIGNEE_TYPE.UNASSIGNED
  ) {
    activeAssigneeTab.value = wootConstants.ASSIGNEE_TYPE.ME;
    autoSwitchedToUnassigned.value = false;
    changed = true;
  }
  if (
    autoSwitchedStatusToAll.value &&
    activeStatus.value === wootConstants.STATUS_TYPE.ALL &&
    previousStatusBeforeBotSwitch.value
  ) {
    activeStatus.value = previousStatusBeforeBotSwitch.value;
    previousStatusBeforeBotSwitch.value = null;
    autoSwitchedStatusToAll.value = false;
    changed = true;
  }
  if (changed) {
    store.dispatch('setChatStatusFilter', activeStatus.value);
    if (!skipFetch) {
      resetAndFetchData();
    }
  }
  return changed;
}

onMounted(async () => {
  store.dispatch('setChatListFilters', conversationFilters.value);
  setFiltersFromUISettings();
  const inboxId = activeInboxId.value;
  if (inboxId) {
    await store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
  }
  applyBotInboxViewDefaults({ skipFetch: true });
  store.dispatch('setChatStatusFilter', activeStatus.value);
  store.dispatch('setChatSortFilter', activeSortBy.value);
  resetAndFetchData();
  if (hasActiveFolders.value) {
    store.dispatch('campaigns/get');
  }
});

watch(activeInboxId, async inboxId => {
  if (inboxId) {
    await store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
  }
  if (applyBotInboxViewDefaults({ skipFetch: true })) {
    store.dispatch('setChatStatusFilter', activeStatus.value);
    resetAndFetchData();
  } else if (restoreBotInboxViewDefaults({ skipFetch: true })) {
    store.dispatch('setChatStatusFilter', activeStatus.value);
    resetAndFetchData();
  } else {
    resetAndFetchData();
  }
});

const deleteConversationDialogRef = ref(null);
const selectedConversationId = ref(null);

async function deleteConversation() {
  try {
    await store.dispatch('deleteConversation', selectedConversationId.value);
    redirectToConversationList();
    selectedConversationId.value = null;
    deleteConversationDialogRef.value.close();
    useAlert(t('CONVERSATION.SUCCESS_DELETE_CONVERSATION'));
  } catch (error) {
    useAlert(t('CONVERSATION.FAIL_DELETE_CONVERSATION'));
  }
}

const handleDelete = conversationId => {
  selectedConversationId.value = conversationId;
  deleteConversationDialogRef.value.open();
};

provide('selectConversation', selectConversation);
provide('deSelectConversation', deSelectConversation);
provide('assignAgent', onAssignAgent);
provide('assignTeam', onAssignTeam);
provide('assignLabels', onAssignLabels);
provide('removeLabels', onRemoveLabels);
provide('updateConversationStatus', handleResolveConversation);
provide('markAsUnread', markAsUnread);
provide('markAsRead', markAsRead);
provide('assignPriority', assignPriority);
provide('isConversationSelected', isConversationSelected);
provide('deleteConversation', handleDelete);

watch(activeTeam, () => resetAndFetchData());

watch(
  computed(() => props.label),
  () => resetAndFetchData()
);
watch(
  computed(() => props.conversationType),
  () => resetAndFetchData()
);

watch(activeFolder, (newVal, oldVal) => {
  if (newVal !== oldVal) {
    store.dispatch('customViews/setActiveConversationFolder', newVal || null);
  }
  resetAndFetchData();
});

watch(chatLists, () => {
  chatsOnView.value = conversationList.value;
});

watch(conversationFilters, (newVal, oldVal) => {
  if (newVal !== oldVal) {
    store.dispatch('updateChatListFilters', newVal);
  }
});
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 conversations-list-wrap bg-n-surface-1 relative"
    :class="[
      { hidden: !showConversationList },
      isOnExpandedLayout ? 'basis-full' : 'w-[340px] 2xl:w-[412px]',
    ]"
  >
    <slot />
    <ChatListHeader
      :page-title="pageTitle"
      :has-applied-filters="hasAppliedFilters"
      :has-active-folders="hasActiveFolders"
      :active-status="activeStatus"
      :is-on-expanded-layout="isOnExpandedLayout"
      :conversation-stats="conversationStats"
      :is-list-loading="chatListLoading && !conversationList.length"
      :is-exporting="isExportingConversations"
      @add-folders="onClickOpenAddFoldersModal"
      @delete-folders="onClickOpenDeleteFoldersModal"
      @filters-modal="onToggleAdvanceFiltersModal"
      @reset-filters="resetAndFetchData"
      @basic-filter-change="onBasicFilterChange"
      @export="openConversationExportDialog"
    />

    <TeleportWithDirection
      v-if="showAddFoldersModal"
      to="#saveFilterTeleportTarget"
    >
      <SaveCustomView
        v-model="appliedFilter"
        :custom-views-query="foldersQuery"
        :open-last-saved-item="openLastSavedItemInFolder"
        @close="onCloseAddFoldersModal"
      />
    </TeleportWithDirection>

    <DeleteCustomViews
      v-if="showDeleteFoldersModal"
      v-model:show="showDeleteFoldersModal"
      :active-custom-view="activeFolder"
      :custom-views-id="foldersId"
      :open-last-item-after-delete="openLastItemAfterDeleteInFolder"
      @close="onCloseDeleteFoldersModal"
    />

    <ChatTypeTabs
      v-if="!hasAppliedFiltersOrActiveFolders"
      :items="assigneeTabItems"
      :active-tab="activeAssigneeTab"
      is-compact
      @chat-tab-change="updateAssigneeTab"
    />

    <p
      v-if="!chatListLoading && !conversationList.length"
      class="flex overflow-auto justify-center items-center p-4"
    >
      {{ $t('CHAT_LIST.LIST.404') }}
    </p>
    <ConversationBulkActions
      :conversations="selectedConversations"
      :all-conversations-selected="allConversationsSelected"
      :selected-inboxes="uniqueInboxes"
      :show-open-action="allSelectedConversationsStatus('open')"
      :show-resolved-action="allSelectedConversationsStatus('resolved')"
      :show-snoozed-action="allSelectedConversationsStatus('snoozed')"
      :class="isOnExpandedLayout && 'sm:!w-[28rem] !w-full'"
      @select-all-conversations="toggleSelectAll"
    />
    <ConversationList
      :conversation-list="conversationList"
      :is-loading="chatListLoading"
      :show-end-of-list-message="showEndOfListMessage"
      :label="label"
      :team-id="teamId"
      :folders-id="foldersId"
      :conversation-type="conversationType"
      :show-assignee="showAssigneeInConversationCard"
      :is-on-expanded-layout="isOnExpandedLayout"
      @load-more="loadMoreConversations"
    />
    <Dialog
      ref="deleteConversationDialogRef"
      type="alert"
      :title="
        $t('CONVERSATION.DELETE_CONVERSATION.TITLE', {
          conversationId: selectedConversationId,
        })
      "
      :description="$t('CONVERSATION.DELETE_CONVERSATION.DESCRIPTION')"
      :confirm-button-label="$t('CONVERSATION.DELETE_CONVERSATION.CONFIRM')"
      @confirm="deleteConversation"
      @close="selectedConversationId = null"
    />
    <TeleportWithDirection
      v-if="showAdvancedFilters"
      to="#conversationFilterTeleportTarget"
    >
      <ConversationFilter
        v-model="appliedFilter"
        :folder-name="activeFolderName"
        :is-folder-view="hasActiveFolders"
        @apply-filter="onApplyFilter"
        @update-folder="onUpdateSavedFilter"
        @close="closeAdvanceFiltersModal"
      />
    </TeleportWithDirection>
    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleResolveWithAttributes"
    />
    <ConversationExportDialog
      ref="conversationExportDialogRef"
      :applied-filters="appliedFiltersForExport"
      :active-folder="activeFolder"
      :list-filters="listFiltersForExport"
      :is-exporting="isExportingConversations"
      @export="onExportConversations"
    />
  </div>
</template>
