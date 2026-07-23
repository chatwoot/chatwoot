<script>
import { mapGetters } from 'vuex';
import ConversationHeader from './ConversationHeader.vue';
import DashboardAppFrame from '../DashboardApp/Frame.vue';
import EmptyState from './EmptyState/EmptyState.vue';
import MessagesView from './MessagesView.vue';

const DASHBOARD_APP_PANEL_STORAGE_KEY = 'dashboard_app_panel_expanded';

export default {
  components: {
    ConversationHeader,
    DashboardAppFrame,
    EmptyState,
    MessagesView,
  },
  props: {
    inboxId: {
      type: [Number, String],
      default: '',
      required: false,
    },
    isInboxView: {
      type: Boolean,
      default: false,
    },
    isContactPanelOpen: {
      type: Boolean,
      default: true,
    },
    isOnExpandedLayout: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      isDashboardAppPanelExpanded:
        localStorage.getItem(DASHBOARD_APP_PANEL_STORAGE_KEY) !== 'false',
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      dashboardApps: 'dashboardApps/getRecords',
    }),
    showContactPanel() {
      return this.isContactPanelOpen && this.currentChat.id;
    },
    showDashboardAppPanel() {
      return this.dashboardApps.length > 0 && Boolean(this.currentChat.id);
    },
  },
  watch: {
    'currentChat.inbox_id': {
      immediate: true,
      handler(inboxId) {
        if (inboxId) {
          this.$store.dispatch('inboxAssignableAgents/fetch', {
            inboxIds: [inboxId],
            includeAgentBots: true,
          });
        }
      },
    },
    'currentChat.id'() {
      this.fetchLabels();
    },
  },
  mounted() {
    this.fetchLabels();
    this.$store.dispatch('dashboardApps/get');
  },
  methods: {
    fetchLabels() {
      if (!this.currentChat.id) {
        return;
      }
      this.$store.dispatch('conversationLabels/get', this.currentChat.id);
    },
    toggleDashboardAppPanel() {
      this.isDashboardAppPanelExpanded = !this.isDashboardAppPanelExpanded;
      localStorage.setItem(
        DASHBOARD_APP_PANEL_STORAGE_KEY,
        String(this.isDashboardAppPanelExpanded)
      );
    },
  },
};
</script>

<template>
  <div
    class="conversation-details-wrap flex flex-col min-w-0 w-full bg-n-surface-1 relative"
    :class="{
      'border-l rtl:border-l-0 rtl:border-r border-n-weak': !isOnExpandedLayout,
    }"
  >
    <ConversationHeader
      v-if="currentChat.id"
      :chat="currentChat"
      :show-back-button="isOnExpandedLayout && !isInboxView"
      class="border-b border-b-n-weak !pt-2"
    />
    <div class="flex flex-row h-full min-h-0 m-0">
      <div class="flex h-full min-h-0 flex-1 min-w-0">
        <MessagesView
          v-if="currentChat.id"
          :inbox-id="inboxId"
          :is-inbox-view="isInboxView"
        />
        <EmptyState
          v-if="!currentChat.id && !isInboxView"
          :is-on-expanded-layout="isOnExpandedLayout"
        />
        <slot />
      </div>
      <!-- Dashboard app side panel (e.g. MSH Profile) — collapsible, next to the chat -->
      <div
        v-if="showDashboardAppPanel"
        class="flex flex-row h-full min-h-0 border-l border-n-weak bg-n-surface-1"
      >
        <button
          class="flex items-start justify-center w-6 pt-3 hover:bg-n-alpha-1 text-n-slate-10 hover:text-n-slate-12"
          :title="
            isDashboardAppPanelExpanded
              ? $t('CONVERSATION.DASHBOARD_APP_PANEL.COLLAPSE')
              : $t('CONVERSATION.DASHBOARD_APP_PANEL.EXPAND')
          "
          @click="toggleDashboardAppPanel"
        >
          <span
            class="size-4"
            :class="
              isDashboardAppPanelExpanded
                ? 'i-lucide-chevrons-right'
                : 'i-lucide-chevrons-left'
            "
          />
        </button>
        <div
          v-show="isDashboardAppPanelExpanded"
          class="w-[360px] h-full min-h-0"
        >
          <DashboardAppFrame
            v-for="(dashboardApp, index) in dashboardApps"
            :key="currentChat.id + '-' + dashboardApp.id"
            :is-visible="isDashboardAppPanelExpanded"
            :config="dashboardApps[index].content"
            :position="index"
            :current-chat="currentChat"
            class="h-full"
          />
        </div>
      </div>
    </div>
  </div>
</template>
