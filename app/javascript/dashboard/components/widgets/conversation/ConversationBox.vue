<template>
  <div
    class="conversation-details-wrap"
    :class="{ 'with-border-left': !isOnExpandedLayout }"
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
    <div v-if="!activeIndex" class="messages-and-sidebar">
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
      v-else
      :key="currentChat.id + '-' + activeIndex"
      :config="dashboardApps[activeIndex - 1].content"
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
  background: var(--color-background-light);

  &.with-border-left {
    border-left: 1px solid var(--color-border);
  }
}

.dashboard-app--tabs {
  background: var(--white);
  margin-top: -1px;
  min-height: var(--dashboard-app-tabs-height);
}

.messages-and-sidebar {
  display: flex;
  background: var(--color-background-light);
  margin: 0;
  height: 100%;
  min-height: 0;
}

.conversation-sidebar-wrap {
  height: auto;
  flex: 0 0;
  overflow: hidden;
  overflow: auto;
  background: white;
  flex-basis: 28rem;

  @include breakpoint(large up) {
    flex-basis: 30em;
  }

  @include breakpoint(xlarge up) {
    flex-basis: 31em;
  }

  @include breakpoint(xxlarge up) {
    flex-basis: 33rem;
  }

  @include breakpoint(xxxlarge up) {
    flex-basis: 40rem;
  }

  &::v-deep .contact--panel {
    width: 100%;
    height: 100%;
    max-width: 100%;
  }
}
</style>
