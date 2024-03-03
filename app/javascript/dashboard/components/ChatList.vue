<template>
  <div
    class="conversations-list-wrap flex-basis-clamp flex-shrink-0 overflow-hidden flex flex-col border-r rtl:border-r-0 rtl:border-l border-slate-50 dark:border-slate-800/50"
    :class="{
      hide: !showConversationList,
      'list--full-width': isOnExpandedLayout,
    }"
  >
    <slot />
    <div
      class="flex items-center justify-between py-0 px-4"
      :class="{
        'pb-3 border-b border-slate-75 dark:border-slate-700':
          hasAppliedFiltersOrActiveFolders,
      }"
    >
      <div class="flex max-w-[85%] justify-center items-center">
        <h1
          class="text-xl break-words overflow-hidden whitespace-nowrap font-medium text-ellipsis text-black-900 dark:text-slate-100 mb-0"
          :title="pageTitle"
        >
          {{ pageTitle }}
        </h1>
        <span
          v-if="!hasAppliedFiltersOrActiveFolders"
          class="p-1 my-0.5 mx-1 rounded-md capitalize bg-slate-50 dark:bg-slate-800 text-xxs text-slate-600 dark:text-slate-300"
        >
          {{ $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${activeStatus}.TEXT`) }}
        </span>
      </div>
      <div class="flex items-center gap-1">
        <div v-if="hasAppliedFilters && !hasActiveFolders">
          <woot-button
            v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON')"
            size="tiny"
            variant="smooth"
            color-scheme="secondary"
            icon="save"
            @click="onClickOpenAddFoldersModal"
          />
          <woot-button
            v-tooltip.top-end="$t('FILTER.CLEAR_BUTTON_LABEL')"
            size="tiny"
            variant="smooth"
            color-scheme="alert"
            icon="dismiss-circle"
            @click="resetAndFetchData"
          />
        </div>
        <div v-if="hasActiveFolders">
          <woot-button
            v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.EDIT.EDIT_BUTTON')"
            size="tiny"
            variant="smooth"
            color-scheme="secondary"
            icon="edit"
            @click="onToggleAdvanceFiltersModal"
          />
          <woot-button
            v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
            size="tiny"
            variant="smooth"
            color-scheme="alert"
            icon="delete"
            @click="onClickOpenDeleteFoldersModal"
          />
        </div>
        <woot-button
          v-else
          v-tooltip.right="$t('FILTER.TOOLTIP_LABEL')"
          variant="smooth"
          color-scheme="secondary"
          icon="filter"
          size="tiny"
          @click="onToggleAdvanceFiltersModal"
        />
        <conversation-basic-filter
          v-if="!hasAppliedFiltersOrActiveFolders"
          @changeFilter="onBasicFilterChange"
        />
      </div>
    </div>

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
      class="overflow-auto p-4 flex justify-center items-center"
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
      class="conversations-list flex-1"
      :class="{ 'overflow-hidden': isContextMenuOpen }"
    >
      <virtual-list
        ref="conversationVirtualList"
        :data-key="'id'"
        :data-sources="conversationList"
        :data-component="itemComponent"
        :extra-props="virtualListExtraProps"
        class="w-full overflow-auto h-full"
        footer-tag="div"
      >
        <template #footer>
          <div v-if="chatListLoading" class="text-center">
            <span class="spinner mt-4 mb-4" />
          </div>
          <p
            v-if="showEndOfListMessage"
            class="text-center text-slate-400 dark:text-slate-300 p-4"
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
import VirtualList from 'vue-virtual-scroll-list';

import ConversationAdvancedFilter from './widgets/conversation/ConversationAdvancedFilter.vue';
import ConversationBasicFilter from './widgets/conversation/ConversationBasicFilter.vue';
import ChatTypeTabs from './widgets/ChatTypeTabs.vue';
import ConversationItem from './ConversationItem.vue';
import timeMixin from '../mixins/time';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import conversationMixin from '../mixins/conversations';
import wootConstants from 'dashboard/constants/globals';
import advancedFilterTypes from './widgets/conversation/advancedFilterItems';
import filterQueryGenerator from '../helper/filterQueryGenerator.js';
import AddCustomViews from 'dashboard/routes/dashboard/customviews/AddCustomViews.vue';
import DeleteCustomViews from 'dashboard/routes/dashboard/customviews/DeleteCustomViews.vue';
import ConversationBulkActions from './widgets/conversation/conversationBulkActions/Index.vue';
import alertMixin from 'shared/mixins/alertMixin';
import filterMixin from 'shared/mixins/filterMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries';
import { generateValuesForEditCustomViews } from 'dashboard/helper/customViewsHelper';

import {
  hasPressedAltAndJKey,
  hasPressedAltAndKKey,
} from 'shared/helpers/KeyboardHelpers';
import { conversationListPageURL } from '../helper/URLHelper';
import {
  isOnMentionsView,
  isOnUnattendedView,
} from '../store/modules/conversations/helpers/actionHelpers';
import { CONVERSATION_EVENTS } from '../helper/AnalyticsHelper/events';
import IntersectionObserver from './IntersectionObserver.vue';

export default {
  components: {
    AddCustomViews,
    ChatTypeTabs,
    // eslint-disable-next-line vue/no-unused-components
    ConversationItem,
    ConversationAdvancedFilter,
    DeleteCustomViews,
    ConversationBulkActions,
    ConversationBasicFilter,
    IntersectionObserver,
    VirtualList,
  },
  mixins: [
    timeMixin,
    conversationMixin,
    eventListenerMixins,
    alertMixin,
    filterMixin,
    uiSettingsMixin,
  ],
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
      selectedConversations: [],
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
    }),
    hasAppliedFilters() {
      return this.appliedFilters.length !== 0;
    },
    hasActiveFolders() {
      return this.activeFolder && this.foldersId !== 0;
    },
    hasAppliedFiltersOrActiveFolders() {
      return this.hasAppliedFilters || this.hasActiveFolders;
    },
    savedFoldersValue() {
      if (this.hasActiveFolders) {
        const payload = this.activeFolder.query;
        this.fetchSavedFilteredConversations(payload);
      }
      return {};
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
        folders: this.hasActiveFolders ? this.savedFoldersValue : undefined,
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
    activeFolder() {
      this.resetAndFetchData();
      this.updateVirtualListProps('foldersId', this.foldersId);
    },
    chatLists() {
      this.chatsOnView = this.conversationList;
    },
    showAssigneeInConversationCard(newVal) {
      this.updateVirtualListProps('showAssignee', newVal);
    },
  },
  mounted() {
    this.setFiltersFromUISettings();
    this.$store.dispatch('setChatStatusFilter', this.activeStatus);
    this.$store.dispatch('setChatSortFilter', this.activeSortBy);
    this.resetAndFetchData();

    if (this.hasActiveFolders) {
      this.$store.dispatch('campaigns/get');
    }

    bus.$on('fetch_conversation_stats', () => {
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
    handleKeyEvents(e) {
      if (hasPressedAltAndJKey(e)) {
        const { allConversations, activeConversationIndex } =
          this.getKeyboardListenerParams();
        if (activeConversationIndex === -1) {
          allConversations[0].click();
        }
        if (activeConversationIndex >= 1) {
          allConversations[activeConversationIndex - 1].click();
        }
      }
      if (hasPressedAltAndKKey(e)) {
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
      }
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
      this.$store
        .dispatch('fetchAllConversations', this.conversationFilters)
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
        bus.$emit('clearSearchInput');
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
      this.selectedConversations = [];
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
      this.selectedConversations.push(conversationId);
      this.selectedInboxes.push(inboxId);
    },
    deSelectConversation(conversationId, inboxId) {
      this.selectedConversations = this.selectedConversations.filter(
        item => item !== conversationId
      );
      this.selectedInboxes = this.selectedInboxes.filter(
        item => item !== inboxId
      );
    },
    selectAllConversations(check) {
      if (check) {
        this.selectedConversations = this.conversationList.map(item => item.id);
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
        this.selectedConversations = [];
        if (conversationId) {
          this.showAlert(
            this.$t(
              'CONVERSATION.CARD_CONTEXT_MENU.API.AGENT_ASSIGNMENT.SUCCESFUL',
              {
                agentName: agent.name,
                conversationId,
              }
            )
          );
        } else {
          this.showAlert(this.$t('BULK_ACTION.ASSIGN_SUCCESFUL'));
        }
      } catch (err) {
        this.showAlert(this.$t('BULK_ACTION.ASSIGN_FAILED'));
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
          this.showAlert(
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
        this.showAlert(
          this.$t(
            'CONVERSATION.CARD_CONTEXT_MENU.API.TEAM_ASSIGNMENT.SUCCESFUL',
            {
              team: team.name,
              conversationId,
            }
          )
        );
      } catch (error) {
        this.showAlert(
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
        this.selectedConversations = [];
        if (conversationId) {
          this.showAlert(
            this.$t(
              'CONVERSATION.CARD_CONTEXT_MENU.API.LABEL_ASSIGNMENT.SUCCESFUL',
              {
                labelName: labels[0],
                conversationId,
              }
            )
          );
        } else {
          this.showAlert(this.$t('BULK_ACTION.LABELS.ASSIGN_SUCCESFUL'));
        }
      } catch (err) {
        this.showAlert(this.$t('BULK_ACTION.LABELS.ASSIGN_FAILED'));
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
        this.selectedConversations = [];
        this.showAlert(this.$t('BULK_ACTION.TEAMS.ASSIGN_SUCCESFUL'));
      } catch (err) {
        this.showAlert(this.$t('BULK_ACTION.TEAMS.ASSIGN_FAILED'));
      }
    },
    async onUpdateConversations(status) {
      try {
        await this.$store.dispatch('bulkActions/process', {
          type: 'Conversation',
          ids: this.selectedConversations,
          fields: {
            status,
          },
        });
        this.selectedConversations = [];
        this.showAlert(this.$t('BULK_ACTION.UPDATE.UPDATE_SUCCESFUL'));
      } catch (err) {
        this.showAlert(this.$t('BULK_ACTION.UPDATE.UPDATE_FAILED'));
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
          this.showAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
          this.isLoading = false;
        });
    },
    allSelectedConversationsStatus(status) {
      if (!this.selectedConversations.length) return false;
      return this.selectedConversations.every(item => {
        return this.$store.getters.getConversationById(item).status === status;
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
.conversations-list-wrap {
  &.hide {
    @apply hidden;
  }

  &.list--full-width {
    @apply basis-full;
  }
}

.conversations-list {
  @apply overflow-hidden hover:overflow-y-auto;
}

.load-more--button {
  @apply text-center rounded-none;
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
