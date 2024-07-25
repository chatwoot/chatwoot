<template>
  <div
    class="flex flex-col flex-shrink-0 overflow-hidden border-r conversations-list-wrap rtl:border-r-0 rtl:border-l border-slate-50 dark:border-slate-800/50"
    :class="[
      { hidden: !showConversationList },
      isOnExpandedLayout ? 'basis-full' : 'flex-basis-clamp',
    ]"
  >
    <slot />
    <chat-list-header
      :page-title="pageTitle"
      :has-applied-filters="hasAppliedFilters"
      :has-active-folders="hasActiveFolders"
      :active-status="activeStatus"
      @add-folders="onClickOpenAddFoldersModal"
      @delete-folders="onClickOpenDeleteFoldersModal"
      @filters-modal="onToggleAdvanceFiltersModal"
      @reset-filters="resetAndFetchData"
      @basic-filter-change="onBasicFilterChange"
    />

    <add-custom-views
      v-if="showAddFoldersModal"
      :custom-views-query="foldersQuery"
      :open-last-saved-item="openLastSavedItemInFolder"
      @close="onCloseAddFoldersModal"
    />

    <delete-custom-views
      v-if="showDeleteFoldersModal"
      :show-delete-popup.sync="showDeleteFoldersModal"
      :active-custom-view="activeFolder"
      :custom-views-id="foldersId"
      :open-last-item-after-delete="openLastItemAfterDeleteInFolder"
      @close="onCloseDeleteFoldersModal"
    />

    <chat-type-tabs
      v-if="!hasAppliedFiltersOrActiveFolders"
      :items="assigneeTabItems"
      :active-tab="activeAssigneeTab"
      class="tab--chat-type"
      @chatTabChange="updateAssigneeTab"
    />

    <p
      v-if="!chatListLoading && !conversationList.length"
      class="flex items-center justify-center p-4 overflow-auto"
    >
      {{ $t('CHAT_LIST.LIST.404') }}
    </p>
    <conversation-bulk-actions
      v-if="selectedConversations.length"
      :conversations="selectedConversations"
      :all-conversations-selected="allConversationsSelected"
      :selected-inboxes="uniqueInboxes"
      :show-open-action="allSelectedConversationsStatus('open')"
      :show-resolved-action="allSelectedConversationsStatus('resolved')"
      :show-snoozed-action="allSelectedConversationsStatus('snoozed')"
      @select-all-conversations="selectAllConversations"
      @assign-agent="onAssignAgent"
      @update-conversations="onUpdateConversations"
      @assign-labels="onAssignLabels"
      @assign-team="onAssignTeamsForBulk"
    />
    <div
      ref="conversationList"
      class="flex-1 conversations-list"
      :class="{ 'overflow-hidden': isContextMenuOpen }"
    >
      <virtual-list
        ref="conversationVirtualList"
        :data-key="'id'"
        :data-sources="conversationList"
        :data-component="itemComponent"
        :extra-props="virtualListExtraProps"
        class="w-full h-full overflow-auto"
        footer-tag="div"
      >
        <template #footer>
          <div v-if="chatListLoading" class="text-center">
            <span class="mt-4 mb-4 spinner" />
          </div>
          <p
            v-if="showEndOfListMessage"
            class="p-4 text-center text-slate-400 dark:text-slate-300"
          >
            {{ $t('CHAT_LIST.EOF') }}
          </p>
          <intersection-observer
            v-if="!showEndOfListMessage && !chatListLoading"
            :options="infiniteLoaderOptions"
            @observed="loadMoreConversations"
          />
        </template>
      </virtual-list>
    </div>
    <woot-modal
      :show.sync="showAdvancedFilters"
      :on-close="closeAdvanceFiltersModal"
      size="medium"
    >
      <conversation-advanced-filter
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

<script>
import { mapGetters } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import VirtualList from 'vue-virtual-scroll-list';

import ChatListHeader from './ChatListHeader.vue';
import ConversationAdvancedFilter from './widgets/conversation/ConversationAdvancedFilter.vue';
import ChatTypeTabs from './widgets/ChatTypeTabs.vue';
import ConversationItem from './ConversationItem.vue';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import conversationMixin from '../mixins/conversations';
import wootConstants from 'dashboard/constants/globals';
import advancedFilterTypes from './widgets/conversation/advancedFilterItems';
import filterQueryGenerator from '../helper/filterQueryGenerator.js';
import AddCustomViews from 'dashboard/routes/dashboard/customviews/AddCustomViews.vue';
import DeleteCustomViews from 'dashboard/routes/dashboard/customviews/DeleteCustomViews.vue';
import ConversationBulkActions from './widgets/conversation/conversationBulkActions/Index.vue';
import filterMixin from 'shared/mixins/filterMixin';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries';
import { generateValuesForEditCustomViews } from 'dashboard/helper/customViewsHelper';
import { conversationListPageURL } from '../helper/URLHelper';
import {
  isOnMentionsView,
  isOnUnattendedView,
} from '../store/modules/conversations/helpers/actionHelpers';
import { CONVERSATION_EVENTS } from '../helper/AnalyticsHelper/events';
import IntersectionObserver from './IntersectionObserver.vue';

export default {
  components: {
    ChatListHeader,
    AddCustomViews,
    ChatTypeTabs,
    // eslint-disable-next-line vue/no-unused-components
    ConversationItem,
    ConversationAdvancedFilter,
    DeleteCustomViews,
    ConversationBulkActions,
    IntersectionObserver,
    VirtualList,
  },
  mixins: [conversationMixin, keyboardEventListenerMixins, filterMixin],
  provide() {
    return {
      // Actions to be performed on virtual list item and context menu.
      selectConversation: this.selectConversation,
      deSelectConversation: this.deSelectConversation,
      assignAgent: this.onAssignAgent,
      assignTeam: this.onAssignTeam,
      assignLabels: this.onAssignLabels,
      updateConversationStatus: this.toggleConversationStatus,
      toggleContextMenu: this.onContextMenuToggle,
      markAsUnread: this.markAsUnread,
      assignPriority: this.assignPriority,
    };
  },
  props: {
    conversationInbox: {
      type: [String, Number],
      default: 0,
    },
    teamId: {
      type: [String, Number],
      default: 0,
    },
    label: {
      type: String,
      default: '',
    },
    conversationType: {
      type: String,
      default: '',
    },
    foldersId: {
      type: [String, Number],
      default: 0,
    },
    showConversationList: {
      default: true,
      type: Boolean,
    },
    isOnExpandedLayout: {
      default: false,
      type: Boolean,
    },
  },
  setup() {
    const { uiSettings } = useUISettings();

    return {
      uiSettings,
    };
  },
  data() {
    return {
      activeAssigneeTab: wootConstants.ASSIGNEE_TYPE.ME,
      activeStatus: wootConstants.STATUS_TYPE.OPEN,
      activeSortBy: wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC,
      showAdvancedFilters: false,
      advancedFilterTypes: advancedFilterTypes.map(filter => ({
        ...filter,
        attributeName: this.$t(`FILTER.ATTRIBUTES.${filter.attributeI18nKey}`),
      })),
      // chatsOnView is to store the chats that are currently visible on the screen,
      // which mirrors the conversationList.
      chatsOnView: [],
      foldersQuery: {},
      showAddFoldersModal: false,
      showDeleteFoldersModal: false,
      selectedInboxes: [],
      isContextMenuOpen: false,
      appliedFilter: [],
      infiniteLoaderOptions: {
        root: this.$refs.conversationList,
        rootMargin: '100px 0px 100px 0px',
      },

      itemComponent: ConversationItem,
      // virtualListExtraProps is to pass the props to the conversationItem component.
      virtualListExtraProps: {
        label: this.label,
        teamId: this.teamId,
        foldersId: this.foldersId,
        conversationType: this.conversationType,
        showAssignee: false,
        isConversationSelected: this.isConversationSelected,
      },
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      chatLists: 'getAllConversations',
      mineChatsList: 'getMineChats',
      allChatList: 'getAllStatusChats',
      chatListFilters: 'getChatListFilters',
      unAssignedChatsList: 'getUnAssignedChats',
      chatListLoading: 'getChatListLoadingStatus',
      currentUserID: 'getCurrentUserID',
      activeInbox: 'getSelectedInbox',
      conversationStats: 'conversationStats/getStats',
      appliedFilters: 'getAppliedConversationFilters',
      folders: 'customViews/getCustomViews',
      inboxes: 'inboxes/getInboxes',
      agentList: 'agents/getAgents',
      teamsList: 'teams/getTeams',
      inboxesList: 'inboxes/getInboxes',
      campaigns: 'campaigns/getAllCampaigns',
      labels: 'labels/getLabels',
      selectedConversations: 'bulkActions/getSelectedConversationIds',
    }),
    hasAppliedFilters() {
      return this.appliedFilters.length !== 0;
    },
    hasActiveFolders() {
      return Boolean(this.activeFolder && this.foldersId !== 0);
    },
    hasAppliedFiltersOrActiveFolders() {
      return this.hasAppliedFilters || this.hasActiveFolders;
    },
    showEndOfListMessage() {
      return (
        this.conversationList.length &&
        this.hasCurrentPageEndReached &&
        !this.chatListLoading
      );
    },
    currentUserDetails() {
      const { id, name } = this.currentUser;
      return {
        id,
        name,
      };
    },
    assigneeTabItems() {
      const ASSIGNEE_TYPE_TAB_KEYS = {
        me: 'mineCount',
        unassigned: 'unAssignedCount',
        all: 'allCount',
      };
      return Object.keys(ASSIGNEE_TYPE_TAB_KEYS).map(key => {
        const count = this.conversationStats[ASSIGNEE_TYPE_TAB_KEYS[key]] || 0;
        return {
          key,
          name: this.$t(`CHAT_LIST.ASSIGNEE_TYPE_TABS.${key}`),
          count,
        };
      });
    },
    showAssigneeInConversationCard() {
      return (
        this.hasAppliedFiltersOrActiveFolders ||
        this.activeAssigneeTab === wootConstants.ASSIGNEE_TYPE.ALL
      );
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.activeInbox);
    },
    currentPage() {
      return this.$store.getters['conversationPage/getCurrentPageFilter'](
        this.activeAssigneeTab
      );
    },
    currentPageFilterKey() {
      return this.hasAppliedFiltersOrActiveFolders
        ? 'appliedFilters'
        : this.activeAssigneeTab;
    },
    currentFiltersPage() {
      return this.$store.getters['conversationPage/getCurrentPageFilter'](
        this.currentPageFilterKey
      );
    },
    hasCurrentPageEndReached() {
      return this.$store.getters['conversationPage/getHasEndReached'](
        this.currentPageFilterKey
      );
    },
    activeAssigneeTabCount() {
      const { activeAssigneeTab } = this;
      const count = this.assigneeTabItems.find(
        item => item.key === activeAssigneeTab
      ).count;
      return count;
    },
    conversationFilters() {
      return {
        inboxId: this.conversationInbox ? this.conversationInbox : undefined,
        assigneeType: this.activeAssigneeTab,
        status: this.activeStatus,
        sortBy: this.activeSortBy,
        page: this.conversationListPagination,
        labels: this.label ? [this.label] : undefined,
        teamId: this.teamId || undefined,
        conversationType: this.conversationType || undefined,
      };
    },
    conversationListPagination() {
      const conversationsPerPage = 25;
      const hasChatsOnView =
        this.chatsOnView &&
        Array.isArray(this.chatsOnView) &&
        !this.chatsOnView.length;
      const isNoFiltersOrFoldersAndChatListNotEmpty =
        !this.hasAppliedFiltersOrActiveFolders && hasChatsOnView;
      const isUnderPerPage =
        this.chatsOnView.length < conversationsPerPage &&
        this.activeAssigneeTabCount < conversationsPerPage &&
        this.activeAssigneeTabCount > this.chatsOnView.length;

      if (isNoFiltersOrFoldersAndChatListNotEmpty && isUnderPerPage) {
        return 1;
      }
      return this.currentPage + 1;
    },
    pageTitle() {
      if (this.hasAppliedFilters) {
        return this.$t('CHAT_LIST.TAB_HEADING');
      }
      if (this.inbox.name) {
        return this.inbox.name;
      }
      if (this.activeTeam.name) {
        return this.activeTeam.name;
      }
      if (this.label) {
        return `#${this.label}`;
      }
      if (this.conversationType === 'mention') {
        return this.$t('CHAT_LIST.MENTION_HEADING');
      }
      if (this.conversationType === 'participating') {
        return this.$t('CONVERSATION_PARTICIPANTS.SIDEBAR_MENU_TITLE');
      }
      if (this.conversationType === 'unattended') {
        return this.$t('CHAT_LIST.UNATTENDED_HEADING');
      }
      if (this.hasActiveFolders) {
        return this.activeFolder.name;
      }
      return this.$t('CHAT_LIST.TAB_HEADING');
    },
    conversationList() {
      let conversationList = [];
      if (!this.hasAppliedFiltersOrActiveFolders) {
        const filters = this.conversationFilters;
        if (this.activeAssigneeTab === 'me') {
          conversationList = [...this.mineChatsList(filters)];
        } else if (this.activeAssigneeTab === 'unassigned') {
          conversationList = [...this.unAssignedChatsList(filters)];
        } else {
          conversationList = [...this.allChatList(filters)];
        }
      } else {
        conversationList = [...this.chatLists];
      }
      return conversationList;
    },
    activeFolder() {
      if (this.foldersId) {
        const activeView = this.folders.filter(
          view => view.id === Number(this.foldersId)
        );
        const [firstValue] = activeView;
        return firstValue;
      }
      return undefined;
    },
    activeFolderName() {
      return this.activeFolder?.name;
    },
    activeTeam() {
      if (this.teamId) {
        return this.$store.getters['teams/getTeam'](this.teamId);
      }
      return {};
    },
    allConversationsSelected() {
      return (
        this.conversationList.length === this.selectedConversations.length &&
        this.conversationList.every(el =>
          this.selectedConversations.includes(el.id)
        )
      );
    },
    uniqueInboxes() {
      return [...new Set(this.selectedInboxes)];
    },
  },
  watch: {
    teamId() {
      this.updateVirtualListProps('teamId', this.teamId);
    },
    activeTeam() {
      this.resetAndFetchData();
    },
    conversationInbox() {
      this.resetAndFetchData();
    },
    label() {
      this.resetAndFetchData();
      this.updateVirtualListProps('label', this.label);
    },
    conversationType() {
      this.resetAndFetchData();
      this.updateVirtualListProps('conversationType', this.conversationType);
    },
    activeFolder(newVal, oldVal) {
      if (newVal !== oldVal) {
        this.$store.dispatch(
          'customViews/setActiveConversationFolder',
          newVal || null
        );
      }
      this.resetAndFetchData();
      this.updateVirtualListProps('foldersId', this.foldersId);
    },
    chatLists() {
      this.chatsOnView = this.conversationList;
    },
    showAssigneeInConversationCard(newVal) {
      this.updateVirtualListProps('showAssignee', newVal);
    },
    conversationFilters(newVal, oldVal) {
      if (newVal !== oldVal) {
        this.$store.dispatch('updateChatListFilters', newVal);
      }
    },
  },
  mounted() {
    this.$store.dispatch('setChatListFilters', this.conversationFilters);
    this.setFiltersFromUISettings();
    this.$store.dispatch('setChatStatusFilter', this.activeStatus);
    this.$store.dispatch('setChatSortFilter', this.activeSortBy);
    this.resetAndFetchData();

    if (this.hasActiveFolders) {
      this.$store.dispatch('campaigns/get');
    }

    this.$emitter.on('fetch_conversation_stats', () => {
      this.$store.dispatch('conversationStats/get', this.conversationFilters);
    });
  },
  methods: {
    updateVirtualListProps(key, value) {
      this.virtualListExtraProps = {
        ...this.virtualListExtraProps,
        [key]: value,
      };
    },
    onApplyFilter(payload) {
      this.resetBulkActions();
      this.foldersQuery = filterQueryGenerator(payload);
      this.$store.dispatch('conversationPage/reset');
      this.$store.dispatch('emptyAllConversations');
      this.fetchFilteredConversations(payload);
    },
    onUpdateSavedFilter(payload, folderName) {
      const payloadData = {
        ...this.activeFolder,
        name: folderName,
        query: filterQueryGenerator(payload),
      };
      this.$store.dispatch('customViews/update', payloadData);
      this.closeAdvanceFiltersModal();
    },
    setFiltersFromUISettings() {
      const { conversations_filter_by: filterBy = {} } = this.uiSettings;
      const { status, order_by: orderBy } = filterBy;
      this.activeStatus = status || wootConstants.STATUS_TYPE.OPEN;
      this.activeSortBy =
        Object.keys(wootConstants.SORT_BY_TYPE).find(
          sortField => sortField === orderBy
        ) || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC;
    },
    onClickOpenAddFoldersModal() {
      this.showAddFoldersModal = true;
    },
    onCloseAddFoldersModal() {
      this.showAddFoldersModal = false;
    },
    onClickOpenDeleteFoldersModal() {
      this.showDeleteFoldersModal = true;
    },
    onCloseDeleteFoldersModal() {
      this.showDeleteFoldersModal = false;
    },
    onToggleAdvanceFiltersModal() {
      if (!this.hasAppliedFilters && !this.hasActiveFolders) {
        this.initializeExistingFilterToModal();
      }
      if (this.hasActiveFolders) {
        this.initializeFolderToFilterModal(this.activeFolder);
      }
      this.showAdvancedFilters = true;
    },
    closeAdvanceFiltersModal() {
      this.showAdvancedFilters = false;
      this.appliedFilter = [];
    },
    setParamsForEditFolderModal() {
      // Here we are setting the params for edit folder modal to show the existing values.

      // For agent, team, inboxes,and campaigns we get only the id's from the query.
      // So we are mapping the id's to the actual values.

      // For labels we get the name of the label from the query.
      // If we delete the label from the label list then we will not be able to show the label name.

      // For custom attributes we get only attribute key.
      // So we are mapping it to find the input type of the attribute to show in the edit folder modal.
      const params = {
        agents: this.agentList,
        teams: this.teamsList,
        inboxes: this.inboxesList,
        labels: this.labels,
        campaigns: this.campaigns,
        languages: languages,
        countries: countries,
        filterTypes: advancedFilterTypes,
        allCustomAttributes: this.$store.getters[
          'attributes/getAttributesByModel'
        ]('conversation_attribute'),
      };
      return params;
    },
    initializeFolderToFilterModal(activeFolder) {
      // Here we are setting the params for edit folder modal.
      //  To show the existing values. when we click on edit folder button.

      // Here we get the query from the active folder.
      // And we are mapping the query to the actual values.
      // To show in the edit folder modal by the help of generateValuesForEditCustomViews helper.
      const query = activeFolder?.query?.payload;
      if (!Array.isArray(query)) return;

      this.appliedFilter.push(
        ...query.map(filter => ({
          attribute_key: filter.attribute_key,
          attribute_model: filter.attribute_model,
          filter_operator: filter.filter_operator,
          values: Array.isArray(filter.values)
            ? generateValuesForEditCustomViews(
                filter,
                this.setParamsForEditFolderModal()
              )
            : [],
          query_operator: filter.query_operator,
          custom_attribute_type: filter.custom_attribute_type,
        }))
      );
    },
    getKeyboardListenerParams() {
      const allConversations = this.$refs.conversationList.querySelectorAll(
        'div.conversations-list div.conversation'
      );
      const activeConversation = this.$refs.conversationList.querySelector(
        'div.conversations-list div.conversation.active'
      );
      const activeConversationIndex = [...allConversations].indexOf(
        activeConversation
      );
      const lastConversationIndex = allConversations.length - 1;
      return {
        allConversations,
        activeConversation,
        activeConversationIndex,
        lastConversationIndex,
      };
    },
    handlePreviousConversation() {
      const { allConversations, activeConversationIndex } =
        this.getKeyboardListenerParams();
      if (activeConversationIndex === -1) {
        allConversations[0].click();
      }
      if (activeConversationIndex >= 1) {
        allConversations[activeConversationIndex - 1].click();
      }
    },
    handleNextConversation() {
      const {
        allConversations,
        activeConversationIndex,
        lastConversationIndex,
      } = this.getKeyboardListenerParams();
      if (activeConversationIndex === -1) {
        allConversations[lastConversationIndex].click();
      } else if (activeConversationIndex < lastConversationIndex) {
        allConversations[activeConversationIndex + 1].click();
      }
    },
    getKeyboardEvents() {
      return {
        'Alt+KeyJ': {
          action: () => this.handlePreviousConversation(),
          allowOnFocusedInput: true,
        },
        'Alt+KeyK': {
          action: () => this.handleNextConversation(),
          allowOnFocusedInput: true,
        },
      };
    },
    resetAndFetchData() {
      this.appliedFilter = [];
      this.resetBulkActions();
      this.$store.dispatch('conversationPage/reset');
      this.$store.dispatch('emptyAllConversations');
      this.$store.dispatch('clearConversationFilters');
      if (this.hasActiveFolders) {
        const payload = this.activeFolder.query;
        this.fetchSavedFilteredConversations(payload);
      }
      if (this.foldersId) {
        return;
      }
      this.fetchConversations();
    },
    fetchConversations() {
      this.$store.dispatch('updateChatListFilters', this.conversationFilters);
      this.$store
        .dispatch('fetchAllConversations')
        .then(this.emitConversationLoaded);
    },
    loadMoreConversations() {
      if (this.hasCurrentPageEndReached || this.chatListLoading) {
        return;
      }
      if (!this.hasAppliedFiltersOrActiveFolders) {
        this.fetchConversations();
      }
      if (this.hasActiveFolders) {
        const payload = this.activeFolder.query;
        this.fetchSavedFilteredConversations(payload);
      }
      if (this.hasAppliedFilters) {
        this.fetchFilteredConversations(this.appliedFilters);
      }
    },
    fetchFilteredConversations(payload) {
      let page = this.currentFiltersPage + 1;
      this.$store
        .dispatch('fetchFilteredConversations', {
          queryData: filterQueryGenerator(payload),
          page,
        })
        .then(this.emitConversationLoaded);
      this.showAdvancedFilters = false;
    },
    fetchSavedFilteredConversations(payload) {
      let page = this.currentFiltersPage + 1;
      this.$store
        .dispatch('fetchFilteredConversations', {
          queryData: payload,
          page,
        })
        .then(this.emitConversationLoaded);
    },
    updateAssigneeTab(selectedTab) {
      if (this.activeAssigneeTab !== selectedTab) {
        this.resetBulkActions();
        this.$emitter.emit('clearSearchInput');
        this.activeAssigneeTab = selectedTab;
        if (!this.currentPage) {
          this.fetchConversations();
        }
      }
    },
    emitConversationLoaded() {
      this.$emit('conversation-load');
      this.$nextTick(() => {
        // Addressing a known issue in the virtual list library where dynamically added items
        // might not render correctly. This workaround involves a slight manual adjustment
        // to the scroll position, triggering the list to refresh its rendering.
        const virtualList = this.$refs.conversationVirtualList;
        const scrollToOffset = virtualList?.scrollToOffset;
        const currentOffset = virtualList?.getOffset() || 0;
        if (scrollToOffset) {
          scrollToOffset(currentOffset + 1);
        }
      });
    },
    resetBulkActions() {
      this.$store.dispatch('bulkActions/clearSelectedConversationIds');
      this.selectedInboxes = [];
    },
    onBasicFilterChange(value, type) {
      if (type === 'status') {
        this.activeStatus = value;
      } else {
        this.activeSortBy = value;
      }
      this.resetAndFetchData();
    },
    openLastSavedItemInFolder() {
      const lastItemOfFolder = this.folders[this.folders.length - 1];
      const lastItemId = lastItemOfFolder.id;
      this.$router.push({
        name: 'folder_conversations',
        params: { id: lastItemId },
      });
    },
    openLastItemAfterDeleteInFolder() {
      if (this.folders.length > 0) {
        this.openLastSavedItemInFolder();
      } else {
        this.$router.push({ name: 'home' });
        this.fetchConversations();
      }
    },
    isConversationSelected(id) {
      return this.selectedConversations.includes(id);
    },
    selectConversation(conversationId, inboxId) {
      this.$store.dispatch(
        'bulkActions/setSelectedConversationIds',
        conversationId
      );
      this.selectedInboxes.push(inboxId);
    },
    deSelectConversation(conversationId, inboxId) {
      this.$store.dispatch(
        'bulkActions/removeSelectedConversationIds',
        conversationId
      );
      this.selectedInboxes = this.selectedInboxes.filter(
        item => item !== inboxId
      );
    },
    selectAllConversations(check) {
      if (check) {
        this.$store.dispatch(
          'bulkActions/setSelectedConversationIds',
          this.conversationList.map(item => item.id)
        );
        this.selectedInboxes = this.conversationList.map(item => item.inbox_id);
      } else {
        this.resetBulkActions();
      }
    },
    // Same method used in context menu, conversationId being passed from there.
    async onAssignAgent(agent, conversationId = null) {
      try {
        await this.$store.dispatch('bulkActions/process', {
          type: 'Conversation',
          ids: conversationId || this.selectedConversations,
          fields: {
            assignee_id: agent.id,
          },
        });
        this.$store.dispatch('bulkActions/clearSelectedConversationIds');
        if (conversationId) {
          useAlert(
            this.$t(
              'CONVERSATION.CARD_CONTEXT_MENU.API.AGENT_ASSIGNMENT.SUCCESFUL',
              {
                agentName: agent.name,
                conversationId,
              }
            )
          );
        } else {
          useAlert(this.$t('BULK_ACTION.ASSIGN_SUCCESFUL'));
        }
      } catch (err) {
        useAlert(this.$t('BULK_ACTION.ASSIGN_FAILED'));
      }
    },
    async assignPriority(priority, conversationId = null) {
      this.$store.dispatch('setCurrentChatPriority', {
        priority,
        conversationId,
      });
      this.$store
        .dispatch('assignPriority', { conversationId, priority })
        .then(() => {
          this.$track(CONVERSATION_EVENTS.CHANGE_PRIORITY, {
            newValue: priority,
            from: 'Context menu',
          });
          useAlert(
            this.$t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SUCCESSFUL', {
              priority,
              conversationId,
            })
          );
        });
    },
    async markAsUnread(conversationId) {
      try {
        await this.$store.dispatch('markMessagesUnread', {
          id: conversationId,
        });
        const {
          params: { accountId, inbox_id: inboxId, label, teamId },
          name,
        } = this.$route;
        let conversationType = '';
        if (isOnMentionsView({ route: { name } })) {
          conversationType = 'mention';
        } else if (isOnUnattendedView({ route: { name } })) {
          conversationType = 'unattended';
        }
        this.$router.push(
          conversationListPageURL({
            accountId,
            conversationType: conversationType,
            customViewId: this.foldersId,
            inboxId,
            label,
            teamId,
          })
        );
      } catch (error) {
        // Ignore error
      }
    },
    async onAssignTeam(team, conversationId = null) {
      try {
        await this.$store.dispatch('assignTeam', {
          conversationId,
          teamId: team.id,
        });
        useAlert(
          this.$t(
            'CONVERSATION.CARD_CONTEXT_MENU.API.TEAM_ASSIGNMENT.SUCCESFUL',
            {
              team: team.name,
              conversationId,
            }
          )
        );
      } catch (error) {
        useAlert(
          this.$t('CONVERSATION.CARD_CONTEXT_MENU.API.TEAM_ASSIGNMENT.FAILED')
        );
      }
    },
    // Same method used in context menu, conversationId being passed from there.
    async onAssignLabels(labels, conversationId = null) {
      try {
        await this.$store.dispatch('bulkActions/process', {
          type: 'Conversation',
          ids: conversationId || this.selectedConversations,
          labels: {
            add: labels,
          },
        });
        this.$store.dispatch('bulkActions/clearSelectedConversationIds');
        if (conversationId) {
          useAlert(
            this.$t(
              'CONVERSATION.CARD_CONTEXT_MENU.API.LABEL_ASSIGNMENT.SUCCESFUL',
              {
                labelName: labels[0],
                conversationId,
              }
            )
          );
        } else {
          useAlert(this.$t('BULK_ACTION.LABELS.ASSIGN_SUCCESFUL'));
        }
      } catch (err) {
        useAlert(this.$t('BULK_ACTION.LABELS.ASSIGN_FAILED'));
      }
    },
    async onAssignTeamsForBulk(team) {
      try {
        await this.$store.dispatch('bulkActions/process', {
          type: 'Conversation',
          ids: this.selectedConversations,
          fields: {
            team_id: team.id,
          },
        });
        this.$store.dispatch('bulkActions/clearSelectedConversationIds');
        useAlert(this.$t('BULK_ACTION.TEAMS.ASSIGN_SUCCESFUL'));
      } catch (err) {
        useAlert(this.$t('BULK_ACTION.TEAMS.ASSIGN_FAILED'));
      }
    },
    async onUpdateConversations(status, snoozedUntil) {
      try {
        await this.$store.dispatch('bulkActions/process', {
          type: 'Conversation',
          ids: this.selectedConversations,
          fields: {
            status,
          },
          snoozed_until: snoozedUntil,
        });
        this.$store.dispatch('bulkActions/clearSelectedConversationIds');
        useAlert(this.$t('BULK_ACTION.UPDATE.UPDATE_SUCCESFUL'));
      } catch (err) {
        useAlert(this.$t('BULK_ACTION.UPDATE.UPDATE_FAILED'));
      }
    },
    toggleConversationStatus(conversationId, status, snoozedUntil) {
      this.$store
        .dispatch('toggleStatus', {
          conversationId,
          status,
          snoozedUntil,
        })
        .then(() => {
          useAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
          this.isLoading = false;
        });
    },
    allSelectedConversationsStatus(status) {
      if (!this.selectedConversations.length) return false;
      return this.selectedConversations.every(item => {
        return this.$store.getters.getConversationById(item)?.status === status;
      });
    },
    onContextMenuToggle(state) {
      this.isContextMenuOpen = state;
    },
  },
};
</script>
<style scoped>
@tailwind components;
@layer components {
  .flex-basis-clamp {
    flex-basis: clamp(20rem, 4vw + 21.25rem, 27.5rem);
  }
}
</style>

<style scoped lang="scss">
.conversations-list {
  @apply overflow-hidden hover:overflow-y-auto;
}

.tab--chat-type {
  @apply py-0 px-4;

  ::v-deep {
    .tabs {
      @apply p-0;
    }
  }
}
</style>
