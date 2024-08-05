<script>
import Logo from './Logo.vue';
import PrimaryNavItem from './PrimaryNavItem.vue';
import OptionsMenu from './OptionsMenu.vue';
import AgentDetails from './AgentDetails.vue';
import NotificationBell from './NotificationBell.vue';
import wootConstants from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';

export default {
  components: {
    Logo,
    PrimaryNavItem,
    OptionsMenu,
    AgentDetails,
    NotificationBell,
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
  methods: {
    frontendURL,
    toggleOptions() {
      this.showOptionsMenu = !this.showOptionsMenu;
    },
    toggleAccountModal() {
      this.$emit('toggleAccounts');
    },
    toggleSupportChatWindow() {
      window.$chatwoot.toggle();
    },
    openNotificationPanel() {
      this.$track(ACCOUNT_EVENTS.OPENED_NOTIFICATIONS);
      this.$emit('openNotificationPanel');
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col justify-between w-16 h-full bg-white border-r dark:bg-slate-900 border-slate-50 dark:border-slate-800/50 rtl:border-l rtl:border-r-0"
  >
    <div class="flex flex-col items-center">
      <Logo
        :source="logoSource"
        :name="installationName"
        :account-id="accountId"
        class="m-4 mb-10"
      />
      <PrimaryNavItem
        v-for="menuItem in menuItems"
        :key="menuItem.toState"
        :icon="menuItem.icon"
        :name="menuItem.label"
        :to="menuItem.toState"
        :is-child-menu-active="menuItem.key === activeMenuItem"
      />
    </div>
    <div class="flex flex-col items-center justify-end pb-6">
      <PrimaryNavItem
        v-if="!isACustomBrandedInstance"
        icon="book-open-globe"
        name="DOCS"
        open-in-new-page
        :to="helpDocsURL"
      />
      <NotificationBell @openNotificationPanel="openNotificationPanel" />
      <AgentDetails @toggleMenu="toggleOptions" />
      <OptionsMenu
        :show="showOptionsMenu"
        @toggleAccounts="toggleAccountModal"
        @showSupportChatWindow="toggleSupportChatWindow"
        @openKeyShortcutModal="$emit('openKeyShortcutModal')"
        @close="toggleOptions"
      />
    </div>
  </div>
</template>
