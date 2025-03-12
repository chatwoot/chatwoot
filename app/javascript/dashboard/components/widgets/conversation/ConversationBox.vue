<script>
import { mapGetters } from 'vuex';
import ConversationHeader from './ConversationHeader.vue';
import DashboardAppFrame from '../DashboardApp/Frame.vue';
import EmptyState from './EmptyState/EmptyState.vue';
import MessagesView from './MessagesView.vue';
import ConversationSidebar from './ConversationSidebar.vue';

export default {
  components: {
    ConversationSidebar,
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
  emits: ['contactPanelToggle'],
  data() {
    return { activeIndex: 0 };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      dashboardApps: 'dashboardApps/getRecords',
    }),
    dashboardAppTabs() {
      return [
        {
          key: 'messages',
          index: 0,
          name: this.$t('CONVERSATION.DASHBOARD_APP_TAB_MESSAGES'),
        },
        ...this.dashboardApps.map((dashboardApp, index) => ({
          key: `dashboard-${dashboardApp.id}`,
          index: index + 1,
          name: dashboardApp.title,
        })),
      ];
    },
    showContactPanel() {
      return this.isContactPanelOpen && this.currentChat.id;
    },
  },
  watch: {
    'currentChat.inbox_id': {
      immediate: true,
      handler(inboxId) {
        if (inboxId) {
          this.$store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
        }
      },
    },
    'currentChat.id'() {
      this.fetchLabels();
      this.activeIndex = 0;
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
    onToggleContactPanel() {
      this.$emit('contactPanelToggle');
    },
    onDashboardAppTabChange(index) {
      this.activeIndex = index;
    },
  },
};
</script>

<template>
  <div
    class="conversation-details-wrap bg-n-background"
    :class="{
      'border-l rtl:border-l-0 rtl:border-r border-n-weak': !isOnExpandedLayout,
    }"
  >
    <ConversationHeader
      v-if="currentChat.id"
      :chat="currentChat"
      :is-inbox-view="isInboxView"
      :is-contact-panel-open="isContactPanelOpen"
      :show-back-button="isOnExpandedLayout && !isInboxView"
      @contact-panel-toggle="onToggleContactPanel"
    />
    <woot-tabs
      v-if="dashboardApps.length && currentChat.id"
      :index="activeIndex"
      class="-mt-px bg-white dashboard-app--tabs dark:bg-slate-900"
      @change="onDashboardAppTabChange"
    >
      <woot-tabs-item
        v-for="tab in dashboardAppTabs"
        :key="tab.key"
        :index="tab.index"
        :name="tab.name"
        :show-badge="false"
      />
    </woot-tabs>
    <div v-show="!activeIndex" class="flex h-full min-h-0 m-0">
      <MessagesView
        v-if="currentChat.id"
        :inbox-id="inboxId"
        :is-inbox-view="isInboxView"
        :is-contact-panel-open="isContactPanelOpen"
        @contact-panel-toggle="onToggleContactPanel"
      />
      <EmptyState
        v-if="!currentChat.id && !isInboxView"
        :is-on-expanded-layout="isOnExpandedLayout"
      />
      <ConversationSidebar
        v-if="showContactPanel"
        :current-chat="currentChat"
        @toggle-contact-panel="onToggleContactPanel"
      />
    </div>
    <DashboardAppFrame
      v-for="(dashboardApp, index) in dashboardApps"
      v-show="activeIndex - 1 === index"
      :key="currentChat.id + '-' + dashboardApp.id"
      :is-visible="activeIndex - 1 === index"
      :config="dashboardApps[index].content"
      :position="index"
      :current-chat="currentChat"
    />
  </div>
</template>

<style lang="scss" scoped>
.conversation-details-wrap {
  @apply flex flex-col min-w-0 w-full;
}

.dashboard-app--tabs {
  ::v-deep {
    .tabs-title {
      a {
        @apply pb-2 pt-1;
      }
    }
  }
}
</style>
