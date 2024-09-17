<script setup>
import {
  ref,
  unref,
  provide,
  computed,
  watch,
  onMounted,
  defineEmits,
} from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import {
  useMapGetter,
  useFunctionGetter,
} from 'dashboard/composables/store.js';

import { DynamicScroller, DynamicScrollerItem } from 'vue-virtual-scroller';
import ChatListHeader from './ChatListHeader.vue';
import ConversationAdvancedFilter from './widgets/conversation/ConversationAdvancedFilter.vue';
import ChatTypeTabs from './widgets/ChatTypeTabs.vue';
import ConversationItem from './ConversationItem.vue';
import AddCustomViews from 'dashboard/routes/dashboard/customviews/AddCustomViews.vue';
import DeleteCustomViews from 'dashboard/routes/dashboard/customviews/DeleteCustomViews.vue';
import ConversationBulkActions from './widgets/conversation/conversationBulkActions/Index.vue';
import IntersectionObserver from './IntersectionObserver.vue';

import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useChatListKeyboardEvents } from 'dashboard/composables/chatlist/useChatListKeyboardEvents';
import { useFilter } from 'shared/composables/useFilter';
import { useTrack } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useEmitter } from 'dashboard/composables/emitter';
import { useEventListener } from '@vueuse/core';

import wootConstants from 'dashboard/constants/globals';
import advancedFilterOptions from './widgets/conversation/advancedFilterItems';
import filterQueryGenerator from '../helper/filterQueryGenerator.js';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries';
import { generateValuesForEditCustomViews } from 'dashboard/helper/customViewsHelper';
import { conversationListPageURL } from '../helper/URLHelper';
import {
  isOnMentionsView,
  isOnUnattendedView,
} from '../store/modules/conversations/helpers/actionHelpers';
import { CONVERSATION_EVENTS } from '../helper/AnalyticsHelper/events';
import { emitter } from 'shared/helpers/mitt';

import 'vue-virtual-scroller/dist/vue-virtual-scroller.css';

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
const router = useRouter();
const store = useStore();

const conversationListRef = ref(null);
const conversationDynamicScroller = ref(null);

const activeAssigneeTab = ref(wootConstants.ASSIGNEE_TYPE.ME);
const activeStatus = ref(wootConstants.STATUS_TYPE.OPEN);
const activeSortBy = ref(wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC);
const showAdvancedFilters = ref(false);
const advancedFilterTypes = ref(
  advancedFilterOptions.map(filter => ({
    ...filter,
    attributeName: t(`FILTER.ATTRIBUTES.${filter.attributeI18nKey}`),
  }))
);
// chatsOnView is to store the chats that are currently visible on the screen,
// which mirrors the conversationList.
const chatsOnView = ref([]);
const foldersQuery = ref({});
const showAddFoldersModal = ref(false);
const showDeleteFoldersModal = ref(false);
const selectedInboxes = ref([]);
const isContextMenuOpen = ref(false);
const appliedFilter = ref([]);

useChatListKeyboardEvents(conversationListRef);

const {
  initializeStatusAndAssigneeFilterToModal,
  initializeInboxTeamAndLabelFilterToModal,
} = useFilter({
  filteri18nKey: 'FILTER',
  attributeModel: 'conversation_attribute',
});

const currentUser = useMapGetter('getCurrentUser');
const chatLists = useMapGetter('getAllConversations');
const mineChatsList = useMapGetter('getMineChats');
const allChatList = useMapGetter('getAllStatusChats');
const unAssignedChatsList = useMapGetter('getUnAssignedChats');
const chatListLoading = useMapGetter('getChatListLoadingStatus');
const activeInbox = useMapGetter('getSelectedInbox');
const conversationStats = useMapGetter('conversationStats/getStats');
const appliedFilters = useMapGetter('getAppliedConversationFilters');
const folders = useMapGetter('customViews/getCustomViews');
const agentList = useMapGetter('agents/getAgents');
const teamsList = useMapGetter('teams/getTeams');
const inboxesList = useMapGetter('inboxes/getInboxes');
const campaigns = useMapGetter('campaigns/getAllCampaigns');
const labels = useMapGetter('labels/getLabels');
const selectedConversations = useMapGetter(
  'bulkActions/getSelectedConversationIds'
);

// computed
const intersectionObserverOptions = computed(() => {
  return {
    root: conversationListRef.value,
    rootMargin: '100px 0px 100px 0px',
  };
});

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

const assigneeTabItems = computed(() => {
  const ASSIGNEE_TYPE_TAB_KEYS = {
    me: 'mineCount',
    unassigned: 'unAssignedCount',
    all: 'allCount',
  };

  return Object.keys(ASSIGNEE_TYPE_TAB_KEYS).map(key => {
    const count = conversationStats.value[ASSIGNEE_TYPE_TAB_KEYS[key]] || 0;
    return {
      key,
      name: t(`CHAT_LIST.ASSIGNEE_TYPE_TABS.${key}`),
      count,
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
    inboxId: props.conversationInbox ? props.conversationInbox : undefined,
    assigneeType: activeAssigneeTab.value,
    status: activeStatus.value,
    sortBy: activeSortBy.value,
    page: conversationListPagination.value,
    labels: props.label ? [props.label] : undefined,
    teamId: props.teamId || undefined,
    conversationType: props.conversationType || undefined,
  };
});

const activeTeam = computed(() => {
  if (props.teamId) {
    return useFunctionGetter('teams/getTeam', props.teamId);
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
  if (props.conversationType === 'mention') {
    return t('CHAT_LIST.MENTION_HEADING');
  }
  if (props.conversationType === 'participating') {
    return t('CONVERSATION_PARTICIPANTS.SIDEBAR_MENU_TITLE');
  }
  if (props.conversationType === 'unattended') {
    return t('CHAT_LIST.UNATTENDED_HEADING');
  }
  if (hasActiveFolders.value) {
    return activeFolder.value.name;
  }
  return t('CHAT_LIST.TAB_HEADING');
});

const conversationList = computed(() => {
  let localConversationList = [];

  if (!hasAppliedFiltersOrActiveFolders.value) {
    const filters = conversationFilters.value;
    if (activeAssigneeTab.value === 'me') {
      localConversationList = [...mineChatsList.value(filters)];
    } else if (activeAssigneeTab.value === 'unassigned') {
      localConversationList = [...unAssignedChatsList.value(filters)];
    } else {
      localConversationList = [...allChatList.value(filters)];
    }
  } else {
    localConversationList = [...chatLists.value];
  }
  return localConversationList;
});

const showEndOfListMessage = computed(() => {
  return (
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
  activeSortBy.value =
    Object.keys(wootConstants.SORT_BY_TYPE).find(
      sortField => sortField === orderBy
    ) || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC;
}

function resetBulkActions() {
  store.dispatch('bulkActions/clearSelectedConversationIds');
  selectedInboxes.value = [];
}

function emitConversationLoaded() {
  emit('conversationLoad');
  // [VITE] removing this since the library has changed
  // nextTick(() => {
  //   // Addressing a known issue in the virtual list library where dynamically added items
  //   // might not render correctly. This workaround involves a slight manual adjustment
  //   // to the scroll position, triggering the list to refresh its rendering.
  //   const virtualList = conversationListRef.value;
  //   const scrollToOffset = virtualList?.scrollToOffset;
  //   const currentOffset = virtualList?.getOffset() || 0;
  //   if (scrollToOffset) {
  //     scrollToOffset(currentOffset + 1);
  //   }
  // });
}

function fetchFilteredConversations(payload) {
  let page = currentFiltersPage.value + 1;
  store
    .dispatch('fetchFilteredConversations', {
      queryData: filterQueryGenerator(payload),
      page,
    })
    .then(emitConversationLoaded);

  showAdvancedFilters.value = false;
}

function fetchSavedFilteredConversations(payload) {
  let page = currentFiltersPage.value + 1;
  store
    .dispatch('fetchFilteredConversations', {
      queryData: payload,
      page,
    })
    .then(emitConversationLoaded);
}

function onApplyFilter(payload) {
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
  const payloadData = {
    ...unref(activeFolder),
    name: unref(folderName),
    query: filterQueryGenerator(payload),
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
  const params = {
    agents: agentList.value,
    teams: teamsList.value,
    inboxes: inboxesList.value,
    labels: labels.value,
    campaigns: campaigns.value,
    languages: languages,
    countries: countries,
    filterTypes: advancedFilterTypes,
    allCustomAttributes: useFunctionGetter(
      'attributes/getAttributesByModel',
      'conversation_attribute'
    ).value,
  };

  return params;
}

function initializeExistingFilterToModal() {
  const statusFilter = initializeStatusAndAssigneeFilterToModal(
    activeStatus.value,
    currentUserDetails.value,
    activeAssigneeTab.value
  );
  if (statusFilter) {
    appliedFilter.value = [...appliedFilter, statusFilter];
  }

  const otherFilters = initializeInboxTeamAndLabelFilterToModal(
    props.conversationInbox,
    inbox.value,
    props.teamId,
    activeTeam.value,
    props.label
  );

  appliedFilter.value = [...appliedFilter, ...otherFilters];
}

function initializeFolderToFilterModal(newActiveFolder) {
  // Here we are setting the params for edit folder modal.
  //  To show the existing values. when we click on edit folder button.

  // Here we get the query from the active folder.
  // And we are mapping the query to the actual values.
  // To show in the edit folder modal by the help of generateValuesForEditCustomViews helper.
  const query = unref(newActiveFolder)?.query?.payload;
  if (!Array.isArray(query)) return;

  const newFilters = query.map(filter => ({
    attribute_key: filter.attribute_key,
    attribute_model: filter.attribute_model,
    filter_operator: filter.filter_operator,
    values: Array.isArray(filter.values)
      ? generateValuesForEditCustomViews(filter, setParamsForEditFolderModal())
      : [],
    query_operator: filter.query_operator,
    custom_attribute_type: filter.custom_attribute_type,
  }));

  appliedFilter.value = [...appliedFilter.value, ...newFilters];
}

function onToggleAdvanceFiltersModal() {
  if (!hasAppliedFilters.value && !hasActiveFolders.value) {
    initializeExistingFilterToModal();
  }
  if (hasActiveFolders.value) {
    initializeFolderToFilterModal(activeFolder.value);
  }

  showAdvancedFilters.value = true;
}

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

  // Increment the current page
  store.dispatch('conversationPage/setCurrentPage', {
    filter: currentPageFilterKey.value,
    page: currentFiltersPage.value + 1,
  });

  if (!hasAppliedFiltersOrActiveFolders.value) {
    fetchConversations();
  } else if (hasActiveFolders.value) {
    const payload = activeFolder.value.query;
    fetchSavedFilteredConversations(payload);
  } else if (hasAppliedFilters.value) {
    fetchFilteredConversations(appliedFilters.value);
  }
}

// Add a method to handle scroll events
function handleScroll() {
  const scroller = conversationDynamicScroller.value;
  if (scroller && scroller.hasScrollbar) {
    const { scrollTop, scrollHeight, clientHeight } = scroller.$el;
    if (scrollHeight - (scrollTop + clientHeight) < 100) {
      loadMoreConversations();
    }
  }
}

function updateAssigneeTab(selectedTab) {
  if (activeAssigneeTab.value !== selectedTab) {
    resetBulkActions();
    emitter.emit('clearSearchInput');
    activeAssigneeTab.value = selectedTab;
    if (!currentPage.value) {
      fetchConversations();
    }
  }
}

function onBasicFilterChange(value, type) {
  if (type === 'status') {
    activeStatus.value = value;
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

function isConversationSelected(id) {
  return selectedConversations.value.includes(id);
}

function selectConversation(conversationId, inboxId) {
  store.dispatch('bulkActions/setSelectedConversationIds', conversationId);
  selectedInboxes.value = [...selectedInboxes.value, inboxId];
}

function deSelectConversation(conversationId, inboxId) {
  store.dispatch('bulkActions/removeSelectedConversationIds', conversationId);
  selectedInboxes.value = selectedInboxes.value.filter(
    item => item !== inboxId
  );
}

function selectAllConversations(check) {
  if (check) {
    store.dispatch(
      'bulkActions/setSelectedConversationIds',
      conversationList.value.map(item => item.id)
    );
    selectedInboxes.value = conversationList.value.map(item => item.inbox_id);
  } else {
    resetBulkActions();
  }
}
// Same method used in context menu, conversationId being passed from there.
async function onAssignAgent(agent, conversationId = null) {
  try {
    await store.dispatch('bulkActions/process', {
      type: 'Conversation',
      ids: conversationId || selectedConversations.value,
      fields: {
        assignee_id: agent.id,
      },
    });
    store.dispatch('bulkActions/clearSelectedConversationIds');
    if (conversationId) {
      useAlert(
        t('CONVERSATION.CARD_CONTEXT_MENU.API.AGENT_ASSIGNMENT.SUCCESFUL', {
          agentName: agent.name,
          conversationId,
        })
      );
    } else {
      useAlert(t('BULK_ACTION.ASSIGN_SUCCESFUL'));
    }
  } catch (err) {
    useAlert(t('BULK_ACTION.ASSIGN_FAILED'));
  }
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
    const {
      params: { accountId, inbox_id: inboxId, label, teamId },
      name,
    } = useRoute();
    let conversationType = '';
    if (isOnMentionsView({ route: { name } })) {
      conversationType = 'mention';
    } else if (isOnUnattendedView({ route: { name } })) {
      conversationType = 'unattended';
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
// Same method used in context menu, conversationId being passed from there.
async function onAssignLabels(newLabels, conversationId = null) {
  try {
    await store.dispatch('bulkActions/process', {
      type: 'Conversation',
      ids: conversationId || selectedConversations.value,
      labels: {
        add: newLabels,
      },
    });
    store.dispatch('bulkActions/clearSelectedConversationIds');
    if (conversationId) {
      useAlert(
        t('CONVERSATION.CARD_CONTEXT_MENU.API.LABEL_ASSIGNMENT.SUCCESFUL', {
          labelName: newLabels[0],
          conversationId,
        })
      );
    } else {
      useAlert(t('BULK_ACTION.LABELS.ASSIGN_SUCCESFUL'));
    }
  } catch (err) {
    useAlert(t('BULK_ACTION.LABELS.ASSIGN_FAILED'));
  }
}
async function onAssignTeamsForBulk(team) {
  try {
    await store.dispatch('bulkActions/process', {
      type: 'Conversation',
      ids: selectedConversations.value,
      fields: {
        team_id: team.id,
      },
    });
    store.dispatch('bulkActions/clearSelectedConversationIds');
    useAlert(t('BULK_ACTION.TEAMS.ASSIGN_SUCCESFUL'));
  } catch (err) {
    useAlert(t('BULK_ACTION.TEAMS.ASSIGN_FAILED'));
  }
}
async function onUpdateConversations(status, snoozedUntil) {
  try {
    await store.dispatch('bulkActions/process', {
      type: 'Conversation',
      ids: selectedConversations.value,
      fields: {
        status,
      },
      snoozed_until: snoozedUntil,
    });
    store.dispatch('bulkActions/clearSelectedConversationIds');
    useAlert(t('BULK_ACTION.UPDATE.UPDATE_SUCCESFUL'));
  } catch (err) {
    useAlert(t('BULK_ACTION.UPDATE.UPDATE_FAILED'));
  }
}

function toggleConversationStatus(conversationId, status, snoozedUntil) {
  store
    .dispatch('toggleStatus', {
      conversationId,
      status,
      snoozedUntil,
    })
    .then(() => {
      useAlert(t('CONVERSATION.CHANGE_STATUS'));
    });
}

function allSelectedConversationsStatus(status) {
  if (!selectedConversations.value.length) return false;
  return selectedConversations.value.every(item => {
    return store.getters.getConversationById(item)?.status === status;
  });
}

function onContextMenuToggle(state) {
  isContextMenuOpen.value = state;
}

useEmitter('fetch_conversation_stats', () => {
  store.dispatch('conversationStats/get', conversationFilters.value);
});

useEventListener(conversationDynamicScroller, 'scroll', handleScroll);

onMounted(() => {
  store.dispatch('setChatListFilters', conversationFilters.value);
  setFiltersFromUISettings();
  store.dispatch('setChatStatusFilter', activeStatus.value);
  store.dispatch('setChatSortFilter', activeSortBy.value);
  resetAndFetchData();
  if (hasActiveFolders.value) {
    store.dispatch('campaigns/get');
  }
});

provide('selectConversation', selectConversation);
provide('deSelectConversation', deSelectConversation);
provide('assignAgent', onAssignAgent);
provide('assignTeam', onAssignTeam);
provide('assignLabels', onAssignLabels);
provide('updateConversationStatus', toggleConversationStatus);
provide('toggleContextMenu', onContextMenuToggle);
provide('markAsUnread', markAsUnread);
provide('assignPriority', assignPriority);
provide('isConversationSelected', isConversationSelected);

watch(activeTeam, () => resetAndFetchData());
watch(props.conversationInbox, () => resetAndFetchData());
watch(props.label, () => resetAndFetchData());
watch(props.conversationType, () => resetAndFetchData());

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
    class="flex flex-col flex-shrink-0 overflow-hidden border-r conversations-list-wrap rtl:border-r-0 rtl:border-l border-slate-50 dark:border-slate-800/50"
    :class="[
      { hidden: !showConversationList },
      isOnExpandedLayout ? 'basis-full' : 'flex-basis-clamp',
    ]"
  >
    <slot />
    <ChatListHeader
      :page-title="pageTitle"
      :has-applied-filters="hasAppliedFilters"
      :has-active-folders="hasActiveFolders"
      :active-status="activeStatus"
      @addFolders="onClickOpenAddFoldersModal"
      @deleteFolders="onClickOpenDeleteFoldersModal"
      @filtersModal="onToggleAdvanceFiltersModal"
      @resetFilters="resetAndFetchData"
      @basicFilterChange="onBasicFilterChange"
    />

    <AddCustomViews
      v-if="showAddFoldersModal"
      :custom-views-query="foldersQuery"
      :open-last-saved-item="openLastSavedItemInFolder"
      @close="onCloseAddFoldersModal"
    />

    <DeleteCustomViews
      v-if="showDeleteFoldersModal"
      :show-delete-popup.sync="showDeleteFoldersModal"
      :active-custom-view="activeFolder"
      :custom-views-id="foldersId"
      :open-last-item-after-delete="openLastItemAfterDeleteInFolder"
      @close="onCloseDeleteFoldersModal"
    />

    <ChatTypeTabs
      v-if="!hasAppliedFiltersOrActiveFolders"
      :items="assigneeTabItems"
      :active-tab="activeAssigneeTab"
      @chatTabChange="updateAssigneeTab"
    />

    <p
      v-if="!chatListLoading && !conversationList.length"
      class="flex items-center justify-center p-4 overflow-auto"
    >
      {{ $t('CHAT_LIST.LIST.404') }}
    </p>
    <ConversationBulkActions
      v-if="selectedConversations.length"
      :conversations="selectedConversations"
      :all-conversations-selected="allConversationsSelected"
      :selected-inboxes="uniqueInboxes"
      :show-open-action="allSelectedConversationsStatus('open')"
      :show-resolved-action="allSelectedConversationsStatus('resolved')"
      :show-snoozed-action="allSelectedConversationsStatus('snoozed')"
      @selectAllConversations="selectAllConversations"
      @assignAgent="onAssignAgent"
      @updateConversations="onUpdateConversations"
      @assignLabels="onAssignLabels"
      @assignTeam="onAssignTeamsForBulk"
    />
    <div
      ref="conversationListRef"
      class="flex-1 conversations-list overflow-hidden hover:overflow-y-auto"
      :class="{ 'overflow-hidden': isContextMenuOpen }"
    >
      <DynamicScroller
        ref="conversationDynamicScroller"
        :items="conversationList"
        :min-item-size="24"
        class="w-full h-full overflow-auto"
        key-field="id"
        page-mode
      >
        <template #default="{ item, index, active }">
          <DynamicScrollerItem
            :item="item"
            :active="active"
            :data-index="index"
            :size-dependencies="[item.content]"
          >
            <ConversationItem
              :source="item"
              :label="label"
              :team-id="teamId"
              :folders-id="foldersId"
              :conversation-type="conversationType"
              :show-assignee="showAssigneeInConversationCard"
              @selectConversation="selectConversation"
              @deSelectConversation="deSelectConversation"
            />
          </DynamicScrollerItem>
        </template>
        <template #after>
          <div v-if="chatListLoading" class="text-center">
            <span class="mt-4 mb-4 spinner" />
          </div>
          <p
            v-else-if="showEndOfListMessage"
            class="p-4 text-center text-slate-400 dark:text-slate-300"
          >
            {{ $t('CHAT_LIST.EOF') }}
          </p>
          <IntersectionObserver
            v-else
            :options="intersectionObserverOptions"
            @observed="loadMoreConversations"
          />
        </template>
      </DynamicScroller>
    </div>
    <woot-modal
      :show.sync="showAdvancedFilters"
      :on-close="closeAdvanceFiltersModal"
      size="medium"
    >
      <ConversationAdvancedFilter
        v-if="showAdvancedFilters"
        :initial-filter-types="advancedFilterTypes"
        :initial-applied-filters="appliedFilter"
        :active-folder-name="activeFolderName"
        :on-close="closeAdvanceFiltersModal"
        :is-folder-view="hasActiveFolders"
        @applyFilter="onApplyFilter"
        @updateFolder="onUpdateSavedFilter"
      />
    </woot-modal>
  </div>
</template>

<style scoped>
@tailwind components;
@layer components {
  .flex-basis-clamp {
    flex-basis: clamp(20rem, 4vw + 21.25rem, 27.5rem);
  }
}
</style>
