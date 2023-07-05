<template>
  <div
    class="conversation-details-wrap bg-slate-25 dark:bg-slate-800"
    :class="{ 'with-border-right': !isOnExpandedLayout }"
  >
    <conversation-header
      v-if="currentChat.id"
      :chat="currentChat"
      :is-contact-panel-open="isContactPanelOpen"
      :show-back-button="isOnExpandedLayout"
      @contact-panel-toggle="onToggleContactPanel"
    />
    <woot-tabs
      v-if="dashboardApps.length && currentChat.id"
      :index="activeIndex"
      class="dashboard-app--tabs"
      @change="onDashboardAppTabChange"
    >
      <woot-tabs-item
        v-for="tab in dashboardAppTabs"
        :key="tab.key"
        :name="tab.name"
        :show-badge="false"
      />
    </woot-tabs>
    <div
      v-show="!activeIndex"
      class="flex bg-slate-25 dark:bg-slate-800 m-0 h-full min-h-0"
    >
      <messages-view
        v-if="currentChat.id"
        :inbox-id="inboxId"
        :is-contact-panel-open="isContactPanelOpen"
        @contact-panel-toggle="onToggleContactPanel"
      />
      <empty-state v-else :is-on-expanded-layout="isOnExpandedLayout" />
      <div v-show="showContactPanel" class="conversation-sidebar-wrap">
        <contact-panel
          v-if="showContactPanel"
          :conversation-id="currentChat.id"
          :inbox-id="currentChat.inbox_id"
          :on-toggle="onToggleContactPanel"
        />
      </div>
    </div>
    <dashboard-app-frame
      v-for="(dashboardApp, index) in dashboardApps"
      v-show="activeIndex - 1 === index"
      :key="currentChat.id + '-' + dashboardApp.id"
      :is-visible="activeIndex - 1 === index"
      :config="dashboardApps[index].content"
      :current-chat="currentChat"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel';
import ConversationHeader from './ConversationHeader';
import DashboardAppFrame from '../DashboardApp/Frame.vue';
import EmptyState from './EmptyState';
import MessagesView from './MessagesView';

export default {
  components: {
    ContactPanel,
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
          name: this.$t('CONVERSATION.DASHBOARD_APP_TAB_MESSAGES'),
        },
        ...this.dashboardApps.map(dashboardApp => ({
          key: `dashboard-${dashboardApp.id}`,
          name: dashboardApp.title,
        })),
      ];
    },
    showContactPanel() {
      return this.isContactPanelOpen && this.currentChat.id;
    },
  },
  watch: {
    'currentChat.inbox_id'(inboxId) {
      if (inboxId) {
        this.$store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
      }
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
      this.$emit('contact-panel-toggle');
    },
    onDashboardAppTabChange(index) {
      this.activeIndex = index;
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/woot';
.conversation-details-wrap {
  display: flex;
  flex-direction: column;
  min-width: 0;
  width: 100%;

  &.with-border-right {
    @apply border-r border-slate-50 dark:border-slate-700;
  }
}

.dashboard-app--tabs {
  background: var(--white);
  margin-top: -1px;
  min-height: var(--dashboard-app-tabs-height);
}

.conversation-sidebar-wrap {
  @apply border-r border-slate-50 dark:border-slate-700;
  background: white;
  flex-basis: 100%;

  @include breakpoint(medium up) {
    flex-basis: 17.5rem;
  }

  @include breakpoint(large up) {
    flex-basis: 18.75rem;
  }

  @include breakpoint(xlarge up) {
    flex-basis: 19.375rem;
  }

  @include breakpoint(xxlarge up) {
    flex-basis: 20.625rem;
  }

  @include breakpoint(xxxlarge up) {
    flex-basis: 25rem;
  }

  &::v-deep .contact--panel {
    width: 100%;
    height: 100%;
    max-width: 100%;
  }
}
</style>
