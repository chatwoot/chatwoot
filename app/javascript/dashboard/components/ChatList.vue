<template>
  <div
    class="conversations-list-wrap"
    :class="{
      hide: !showConversationList,
      'list--full-width': isOnExpandedLayout,
    }"
  >
    <slot />
    <div
      class="chat-list__top"
      :class="{ filter__applied: hasAppliedFiltersOrActiveFolders }"
    >
      <h1 class="page-title text-truncate" :title="pageTitle">
        {{ pageTitle }}
      </h1>

      <div class="filter--actions">
        <chat-filter
          v-if="!hasAppliedFiltersOrActiveFolders"
          @statusFilterChange="updateStatusType"
        />
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
            v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
            size="tiny"
            variant="smooth"
            color-scheme="alert"
            icon="delete"
            class="delete-custom-view__button"
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

    <p v-if="!chatListLoading && !conversationList.length" class="content-box">
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
      ref="activeConversation"
      class="conversations-list"
      :class="{ 'is-context-menu-open': isContextMenuOpen }"
    >
      <conversation-card
        v-for="chat in conversationList"
        :key="chat.id"
        :active-label="label"
        :team-id="teamId"
        :folders-id="foldersId"
        :chat="chat"
        :conversation-type="conversationType"
        :show-assignee="showAssigneeInConversationCard"
        :selected="isConversationSelected(chat.id)"
        @select-conversation="selectConversation"
        @de-select-conversation="deSelectConversation"
        @assign-agent="onAssignAgent"
        @assign-team="onAssignTeam"
        @assign-label="onAssignLabels"
        @update-conversation-status="toggleConversationStatus"
        @context-menu-toggle="onContextMenuToggle"
        @mark-as-unread="markAsUnread"
      />

      <div v-if="chatListLoading" class="text-center">
        <span class="spinner" />
      </div>

      <woot-button
        v-if="!hasCurrentPageEndReached && !chatListLoading"
        variant="clear"
        size="expanded"
        @click="loadMoreConversations"
      >
        {{ $t('CHAT_LIST.LOAD_MORE_CONVERSATIONS') }}
      </woot-button>

      <p
        v-if="showEndOfListMessage"
        class="text-center text-muted end-of-list-text"
      >
        {{ $t('CHAT_LIST.EOF') }}
      </p>
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
        :on-close="closeAdvanceFiltersModal"
        @applyFilter="onApplyFilter"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ChatFilter from './widgets/conversation/ChatFilter';
import ConversationAdvancedFilter from './widgets/conversation/ConversationAdvancedFilter';
import ChatTypeTabs from './widgets/ChatTypeTabs';
import ConversationCard from './widgets/conversation/ConversationCard';
import timeMixin from '../mixins/time';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import conversationMixin from '../mixins/conversations';
import wootConstants from '../constants';
import advancedFilterTypes from './widgets/conversation/advancedFilterItems';
import filterQueryGenerator from '../helper/filterQueryGenerator.js';
import AddCustomViews from 'dashboard/routes/dashboard/customviews/AddCustomViews';
import DeleteCustomViews from 'dashboard/routes/dashboard/customviews/DeleteCustomViews.vue';
import ConversationBulkActions from './widgets/conversation/conversationBulkActions/Index.vue';
import alertMixin from 'shared/mixins/alertMixin';
import filterMixin from 'shared/mixins/filterMixin';

import {
  hasPressedAltAndJKey,
  hasPressedAltAndKKey,
} from 'shared/helpers/KeyboardHelpers';
import { conversationListPageURL } from '../helper/URLHelper';
import {
  isOnMentionsView,
  isOnUnattendedView,
} from '../store/modules/conversations/helpers/actionHelpers';

export default {
  components: {
    AddCustomViews,
    ChatTypeTabs,
    ConversationCard,
    ChatFilter,
    ConversationAdvancedFilter,
    DeleteCustomViews,
    ConversationBulkActions,
  },
  mixins: [
    timeMixin,
    conversationMixin,
    eventListenerMixins,
    alertMixin,
    filterMixin,
  ],
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
      showAdvancedFilters: false,
      advancedFilterTypes: advancedFilterTypes.map(filter => ({
        ...filter,
        attributeName: this.$t(`FILTER.ATTRIBUTES.${filter.attributeI18nKey}`),
      })),
      foldersQuery: {},
      showAddFoldersModal: false,
      showDeleteFoldersModal: false,
      selectedConversations: [],
      selectedInboxes: [],
      isContextMenuOpen: false,
      appliedFilter: [],
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
    conversationFilters() {
      return {
        inboxId: this.conversationInbox ? this.conversationInbox : undefined,
        assigneeType: this.activeAssigneeTab,
        status: this.activeStatus,
        page: this.currentPage + 1,
        labels: this.label ? [this.label] : undefined,
        teamId: this.teamId || undefined,
        conversationType: this.conversationType || undefined,
        folders: this.hasActiveFolders ? this.savedFoldersValue : undefined,
      };
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
    activeTeam() {
      this.resetAndFetchData();
    },
    conversationInbox() {
      this.resetAndFetchData();
    },
    label() {
      this.resetAndFetchData();
    },
    conversationType() {
      this.resetAndFetchData();
    },
    activeFolder() {
      if (!this.hasAppliedFilters) {
        this.resetAndFetchData();
      }
    },
  },
  mounted() {
    this.$store.dispatch('setChatFilter', this.activeStatus);
    this.resetAndFetchData();

    bus.$on('fetch_conversation_stats', () => {
      this.$store.dispatch('conversationStats/get', this.conversationFilters);
    });
  },
  methods: {
    onApplyFilter(payload) {
      this.resetBulkActions();
      this.foldersQuery = filterQueryGenerator(payload);
      this.$store.dispatch('conversationPage/reset');
      this.$store.dispatch('emptyAllConversations');
      this.fetchFilteredConversations(payload);
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
      if (!this.hasAppliedFilters) {
        this.initializeExistingFilterToModal();
      }
      this.showAdvancedFilters = true;
    },
    closeAdvanceFiltersModal() {
      this.showAdvancedFilters = false;
      this.appliedFilter = [];
    },
    getKeyboardListenerParams() {
      const allConversations = this.$refs.activeConversation.querySelectorAll(
        'div.conversations-list div.conversation'
      );
      const activeConversation = this.$refs.activeConversation.querySelector(
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
        const {
          allConversations,
          activeConversationIndex,
        } = this.getKeyboardListenerParams();
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
      this.appliedFilter = [];
    },
    fetchConversations() {
      this.$store
        .dispatch('fetchAllConversations', this.conversationFilters)
        .then(() => this.$emit('conversation-load'));
    },
    loadMoreConversations() {
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
        .then(() => this.$emit('conversation-load'));
      this.showAdvancedFilters = false;
    },
    fetchSavedFilteredConversations(payload) {
      let page = this.currentFiltersPage + 1;
      this.$store
        .dispatch('fetchFilteredConversations', {
          queryData: payload,
          page,
        })
        .then(() => this.$emit('conversation-load'));
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
    resetBulkActions() {
      this.selectedConversations = [];
      this.selectedInboxes = [];
    },
    updateStatusType(index) {
      if (this.activeStatus !== index) {
        this.activeStatus = index;
        this.resetAndFetchData();
      }
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

<style scoped lang="scss">
@import '~dashboard/assets/scss/woot';

.spinner {
  margin-top: var(--space-normal);
  margin-bottom: var(--space-normal);
}

.conversations-list {
  // Prevent the list from scrolling if the submenu is opened
  &.is-context-menu-open {
    overflow: hidden !important;
  }
}

.conversations-list-wrap {
  flex-shrink: 0;
  flex-basis: clamp(32rem, 4vw + 34rem, 44rem);
  overflow: hidden;

  &.hide {
    display: none;
  }

  &.list--full-width {
    flex-basis: 100%;
  }
}
.filter--actions {
  display: flex;
  align-items: center;
}

.filter__applied {
  padding: 0 0 var(--space-slab) 0 !important;
  border-bottom: 1px solid var(--color-border);
}

.delete-custom-view__button {
  margin-right: var(--space-normal);
}

.tab--chat-type {
  padding: 0 var(--space-normal);

  ::v-deep {
    .tabs {
      padding: 0;
    }
  }
}
</style>
