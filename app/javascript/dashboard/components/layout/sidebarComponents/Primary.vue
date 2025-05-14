<script>
import Logo from './Logo.vue';
import PrimaryNavItem from './PrimaryNavItem.vue';
import OptionsMenu from './OptionsMenu.vue';
import AgentDetails from './AgentDetails.vue';
import NotificationBell from './NotificationBell.vue';
import wootConstants from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';

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
  emits: ['toggleAccounts', 'openNotificationPanel', 'openKeyShortcutModal'],
  data() {
    return {
      helpDocsURL: wootConstants.DOCS_URL,
      showOptionsMenu: false,
      pinSidebar: !!localStorage.getItem('pin-sidebar'),
    };
  },
  watch: {
    pinSidebar(value) {
      localStorage.setItem('pin-sidebar', value ? '1' : '');
    },
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
      useTrack(ACCOUNT_EVENTS.OPENED_NOTIFICATIONS);
      this.$emit('openNotificationPanel');
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col justify-between h-full bg-white border-r dark:bg-slate-900 border-slate-50 dark:border-slate-800/50 rtl:border-l rtl:border-r-0 w-16 hover:w-[210px]"
    :class="{
      'w-[210px]': pinSidebar,
    }"
    :style="{
      transition: 'width 0.25s',
      'transition-timing-function': 'ease-in-out',
    }"
  >
    <div class="flex-1 flex flex-col justify-stretch h-full">
      <div class="flex flex-row m-4 mb-5">
        <div class="flex-1">
          <Logo
            :source="logoSource"
            :name="installationName"
            :account-id="accountId"
          />
        </div>
        <button class="ml-4" @click="() => (pinSidebar = !pinSidebar)">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="1.5em"
            height="1.5em"
            viewBox="0 0 20 20"
          >
            <!-- Icon from Fluent UI System Icons by Microsoft Corporation - https://github.com/microsoft/fluentui-system-icons/blob/main/LICENSE -->
            <path
              fill="currentColor"
              d="M5 3a3 3 0 0 0-3 3v7a3 3 0 0 0 3 3h10a3 3 0 0 0 3-3V6a3 3 0 0 0-3-3zm10 1a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H8.5V4z"
            />
          </svg>
        </button>
      </div>
      <div class="flex-1 flex flex-col overflow-auto">
        <div class="flex flex-col items-stretch">
          <PrimaryNavItem
            v-for="menuItem in menuItems"
            :id="menuItem.key"
            :key="menuItem.toState"
            :icon="menuItem.icon"
            :name="menuItem.label"
            :to="menuItem.toState"
            :icon-fill-rule="menuItem.iconFillRule"
            :icon-clip-rule="menuItem.iconClipRule"
            :is-child-menu-active="menuItem.key === activeMenuItem"
          />
        </div>
      </div>
      <div class="flex flex-col items-stretch justify-stretch pb-6">
        <a
          v-if="!isACustomBrandedInstance"
          v-tooltip.right="$t(`SIDEBAR.DOCS`)"
          :href="helpDocsURL"
          class="relative flex flex-row items-center m-3 px-2 gap-2 h-10 my-1 rounded-lg text-slate-700 dark:text-slate-100 hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600"
          rel="noopener noreferrer nofollow"
          target="_blank"
        >
          <div
            :style="{
              marginLeft: '1.5px',
            }"
          >
            <fluent-icon icon="book-open-globe-new" />
          </div>
          <span class="flex-1 line-clamp-1">{{ $t(`SIDEBAR.DOCS`) }}</span>
          <span class="sr-only">{{ $t(`SIDEBAR.DOCS`) }}</span>
        </a>
        <NotificationBell
          class="mx-3"
          @open-notification-panel="openNotificationPanel"
        />
        <div class="mx-4">
          <AgentDetails @toggle-menu="toggleOptions" />
        </div>
        <OptionsMenu
          :show="showOptionsMenu"
          @toggle-accounts="toggleAccountModal"
          @show-support-chat-window="toggleSupportChatWindow"
          @open-key-shortcut-modal="$emit('openKeyShortcutModal')"
          @close="toggleOptions"
        />
      </div>
    </div>
  </div>
</template>
