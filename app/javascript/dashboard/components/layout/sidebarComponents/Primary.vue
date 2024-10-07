<template>
  <div
    class="h-full w-16 bg-white dark:bg-slate-900 border-r border-slate-50 dark:border-slate-800/50 rtl:border-l rtl:border-r-0 flex justify-between flex-col"
  >
    <div class="flex flex-col items-center">
      <logo
        :source="logoSource"
        :name="installationName"
        :account-id="accountId"
        class="m-4 mb-10"
      />
      <primary-nav-item
        v-for="menuItem in menuItems"
        :key="menuItem.toState"
        :icon="menuItem.icon"
        :name="menuItem.label"
        :to="menuItem.toState"
        :is-child-menu-active="menuItem.key === activeMenuItem"
      />
    </div>
    <div class="flex flex-col items-center justify-end pb-6">
      <new-ticket-button 
        v-if="newTicketEnabled"
        v-tooltip.right="$t('SIDEBAR.NEW_TICKET')"
        @open-new-ticket-panel="openNewTicketPanel"
      />

      <primary-nav-item
        v-if="!isACustomBrandedInstance"
        icon="book-open-globe"
        name="DOCS"
        :open-in-new-page="true"
        :to="helpDocsURL"
      />
      <notification-bell @open-notification-panel="openNotificationPanel" />
      <agent-details @toggle-menu="toggleOptions" />
      <options-menu
        :show="showOptionsMenu"
        @toggle-accounts="toggleAccountModal"
        @show-support-chat-window="toggleSupportChatWindow"
        @key-shortcut-modal="$emit('key-shortcut-modal')"
        @close="toggleOptions"
      />
    </div>
  </div>
</template>
<script>
import Logo from './Logo.vue';
import PrimaryNavItem from './PrimaryNavItem.vue';
import OptionsMenu from './OptionsMenu.vue';
import AgentDetails from './AgentDetails.vue';
import NotificationBell from './NotificationBell.vue';
import NewTicketButton from './NewTicketButton.vue';
import wootConstants from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { mapGetters } from 'vuex';
import { FEATURE_FLAGS } from '../../../featureFlags';

export default {
  components: {
    Logo,
    PrimaryNavItem,
    OptionsMenu,
    AgentDetails,
    NotificationBell,
    NewTicketButton,
  },
  props: {
    isACustomBrandedInstance: {
      type: Boolean,
      default: false,
    },
    logoSource: {
      type: String,
      default: '',
    },
    installationName: {
      type: String,
      default: '',
    },
    accountId: {
      type: Number,
      default: 0,
    },
    menuItems: {
      type: Array,
      default: () => [],
    },
    activeMenuItem: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      helpDocsURL: wootConstants.DOCS_URL,
      showOptionsMenu: false,
    };
  },
  computed: {
    ...mapGetters({
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    newTicketEnabled(){
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.TICKETS
      );
    }
  },
  methods: {
    frontendURL,
    toggleOptions() {
      this.showOptionsMenu = !this.showOptionsMenu;
    },
    toggleAccountModal() {
      this.$emit('toggle-accounts');
    },
    toggleSupportChatWindow() {
      window.$chatwoot.toggle();
    },
    openNotificationPanel() {
      this.$track(ACCOUNT_EVENTS.OPENED_NOTIFICATIONS);
      this.$emit('open-notification-panel');
    },
    openNewTicketPanel() {
      this.$emit('open-new-ticket-panel');
    },
  },
};
</script>
