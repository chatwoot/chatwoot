<template>
  <div class="primary--sidebar">
    <logo
      :source="logoSource"
      :name="installationName"
      :account-id="accountId"
    />
    <nav class="menu vertical">
      <primary-nav-item
        v-for="menuItem in menuItems"
        :key="menuItem.toState"
        :icon="menuItem.icon"
        :name="menuItem.label"
        :to="menuItem.toState"
        :is-child-menu-active="isMenuActive(menuItem, $route.name)"
      />
    </nav>
    <div class="menu vertical user-menu">
      <notification-bell />
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
import Logo from './Logo';
import PrimaryNavItem from './PrimaryNavItem';
import OptionsMenu from 'dashboard/components/layout/sidebarComponents/OptionsMenu';
import AgentDetails from 'dashboard/components/layout/sidebarComponents/AgentDetails';
import NotificationBell from 'dashboard/components/layout/sidebarComponents/NotificationBell';

import { frontendURL } from 'dashboard/helper/URLHelper';

export default {
  components: {
    Logo,
    PrimaryNavItem,
    OptionsMenu,
    AgentDetails,
    NotificationBell,
  },
  props: {
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
  },
  data() {
    return {
      showOptionsMenu: false,
    };
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
    isMenuActive(menuItem, currentRouteName) {
      const { key = '' } = menuItem;

      if (currentRouteName === key) return true;
      // Conversations route is defaulted as home
      // TODO: Needs to ewfactor old statenames to follow a structure while key naming.
      if (currentRouteName.includes('inbox') && key === 'conversations')
        return true;
      if (currentRouteName.includes('conversations') && key === 'conversations')
        return true;
      return false;
    },
  },
};
</script>
<style lang="scss" scoped>
.primary--sidebar {
  display: flex;
  flex-direction: column;
  width: var(--space-jumbo);
  border-right: 1px solid var(--s-50);
  box-sizing: content-box;
  height: 100vh;
  flex-shrink: 0;
}

.menu {
  align-items: center;
  margin-top: var(--space-medium);
}

.user-menu {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  justify-content: flex-end;
  margin-bottom: var(--space-normal);
}
</style>
