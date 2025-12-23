<script setup>
import { h, computed, onMounted } from 'vue';
import { provideSidebarContext } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useStorage } from '@vueuse/core';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import { vOnClickOutside } from '@vueuse/components';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useAdmin } from 'dashboard/composables/useAdmin';

import Button from 'dashboard/components-next/button/Button.vue';
import SidebarGroup from './SidebarGroup.vue';
import SidebarProfileMenu from './SidebarProfileMenu.vue';
import SidebarChangelogCard from './SidebarChangelogCard.vue';
import YearInReviewBanner from '../year-in-review/YearInReviewBanner.vue';
import ChannelLeaf from './ChannelLeaf.vue';
import SidebarAccountSwitcher from './SidebarAccountSwitcher.vue';
import Logo from 'next/icon/Logo.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';

const props = defineProps({
  isMobileSidebarOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'closeKeyShortcutModal',
  'openKeyShortcutModal',
  'showCreateAccountModal',
  'closeMobileSidebar',
]);

const { accountScopedRoute, isOnChatwootCloud } = useAccount();
const store = useStore();
const searchShortcut = useKbd([`$mod`, 'k']);
const { t } = useI18n();
const { isAdmin } = useAdmin();

const isACustomBrandedInstance = useMapGetter(
  'globalConfig/isACustomBrandedInstance'
);
const adminFirst = useMapGetter('globalConfig/adminFirst');

const toggleShortcutModalFn = show => {
  if (show) {
    emit('openKeyShortcutModal');
  } else {
    emit('closeKeyShortcutModal');
  }
};

useSidebarKeyboardShortcuts(toggleShortcutModalFn);

// We're using localStorage to store the expanded item in the sidebar
// This helps preserve context when navigating between portal and dashboard layouts
// and also when the user refreshes the page
const expandedItem = useStorage(
  'next-sidebar-expanded-item',
  null,
  sessionStorage
);

const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};
provideSidebarContext({
  expandedItem,
  setExpandedItem,
});

const inboxes = useMapGetter('inboxes/getInboxes');
const labels = useMapGetter('labels/getLabelsOnSidebar');
const teams = useMapGetter('teams/getMyTeams');
const contactCustomViews = useMapGetter('customViews/getContactCustomViews');
const conversationCustomViews = useMapGetter(
  'customViews/getConversationCustomViews'
);

onMounted(() => {
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
  store.dispatch('notifications/unReadCount');
  store.dispatch('teams/get');
  store.dispatch('attributes/get');
  store.dispatch('customViews/get', 'conversation');
  store.dispatch('customViews/get', 'contact');
});

const sortedInboxes = computed(() =>
  inboxes.value.slice().sort((a, b) => a.name.localeCompare(b.name))
);

const closeMobileSidebar = () => {
  if (!props.isMobileSidebarOpen) return;
  emit('closeMobileSidebar');
};

const onComposeOpen = toggleFn => {
  toggleFn();
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
};

const onComposeClose = () => {
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
};

const newReportRoutes = () => [
  {
    name: 'Reports Agent',
    label: t('SIDEBAR.REPORTS_AGENT'),
    to: accountScopedRoute('agent_reports_index'),
    activeOn: ['agent_reports_show'],
  },
  {
    name: 'Reports Label',
    label: t('SIDEBAR.REPORTS_LABEL'),
    to: accountScopedRoute('label_reports_index'),
  },
  {
    name: 'Reports Inbox',
    label: t('SIDEBAR.REPORTS_INBOX'),
    to: accountScopedRoute('inbox_reports_index'),
    activeOn: ['inbox_reports_show'],
  },
  {
    name: 'Reports Team',
    label: t('SIDEBAR.REPORTS_TEAM'),
    to: accountScopedRoute('team_reports_index'),
    activeOn: ['team_reports_show'],
  },
];

const reportRoutes = computed(() => newReportRoutes());

const isAdminFirstMode = computed(() => {
  return isAdmin.value && adminFirst.value;
});

const menuItems = computed(() => {
  // Menu para COLABORADOR (atendente)
  const collaboratorMenu = [
    {
      name: 'Dashboard',
      label: t('SIDEBAR.DASHBOARD'),
      icon: 'i-lucide-layout-dashboard',
      to: accountScopedRoute('home'),
      activeOn: ['home', 'inbox_conversation'],
    },
    {
      name: 'Attendances',
      label: t('SIDEBAR.ATTENDANCES'),
      icon: 'i-lucide-message-circle',
      to: accountScopedRoute('home'),
      activeOn: ['home', 'inbox_conversation'],
    },
    {
      name: 'Waiting Attendance',
      label: t('SIDEBAR.WAITING_ATTENDANCE'),
      icon: 'i-lucide-clock',
      to: accountScopedRoute('conversation_unattended'),
      activeOn: ['conversation_unattended', 'conversation_through_unattended'],
    },
    {
      name: 'People',
      label: t('SIDEBAR.PEOPLE'),
      icon: 'i-lucide-contact',
      to: accountScopedRoute('contacts_dashboard_index', {}, { page: 1, search: undefined }),
      activeOn: ['contacts_dashboard_index', 'contacts_edit'],
    },
    {
      name: 'Reports',
      label: t('SIDEBAR.REPORTS'),
      icon: 'i-lucide-chart-spline',
      to: accountScopedRoute('account_overview_reports'),
      activeOn: [
        'account_overview_reports',
        'conversation_reports',
        'agent_reports_index',
        'agent_reports_show',
        'label_reports_index',
        'inbox_reports_index',
        'inbox_reports_show',
        'team_reports_index',
        'team_reports_show',
        'csat_reports',
        'sla_reports',
        'bot_reports',
      ],
    },
  ];

  // Menu para ADMIN
  const adminMenu = [
    {
      name: 'Dashboard',
      label: t('SIDEBAR.DASHBOARD'),
      icon: 'i-lucide-layout-dashboard',
      to: accountScopedRoute('home'),
      activeOn: ['home', 'inbox_conversation'],
    },
    {
      name: 'Attendances',
      label: t('SIDEBAR.ATTENDANCES'),
      icon: 'i-lucide-message-circle',
      to: accountScopedRoute('home'),
      activeOn: ['home', 'inbox_conversation'],
    },
    {
      name: 'Reports',
      label: t('SIDEBAR.REPORTS'),
      icon: 'i-lucide-chart-spline',
      to: accountScopedRoute('account_overview_reports'),
      activeOn: [
        'account_overview_reports',
        'conversation_reports',
        'agent_reports_index',
        'agent_reports_show',
        'label_reports_index',
        'inbox_reports_index',
        'inbox_reports_show',
        'team_reports_index',
        'team_reports_show',
        'csat_reports',
        'sla_reports',
        'bot_reports',
      ],
    },
    {
      name: 'Users',
      label: t('SIDEBAR.USERS'),
      icon: 'i-lucide-square-user',
      to: accountScopedRoute('agent_list'),
      activeOn: ['agent_list'],
    },
    {
      name: 'Teams',
      label: t('SIDEBAR.TEAMS'),
      icon: 'i-lucide-users',
      to: accountScopedRoute('settings_teams_list'),
      activeOn: ['settings_teams_list'],
    },
    {
      name: 'Channels',
      label: t('SIDEBAR.CHANNELS'),
      icon: 'i-lucide-mailbox',
      to: accountScopedRoute('settings_inbox_list'),
      activeOn: ['settings_inbox_list'],
    },
    {
      name: 'Automation Rules',
      label: t('SIDEBAR.AUTOMATION_RULES'),
      icon: 'i-lucide-workflow',
      to: accountScopedRoute('automation_list'),
      activeOn: ['automation_list'],
    },
    {
      name: 'Integrations',
      label: t('SIDEBAR.INTEGRATIONS'),
      icon: 'i-lucide-blocks',
      to: accountScopedRoute('settings_applications'),
      activeOn: ['settings_applications'],
    },
    {
      name: 'Settings',
      label: t('SIDEBAR.SETTINGS'),
      icon: 'i-lucide-bolt',
      to: accountScopedRoute('general_settings_index'),
      activeOn: [
        'general_settings_index',
        'agent_list',
        'settings_teams_list',
        'assignment_policy_index',
        'settings_inbox_list',
        'labels_list',
        'attributes_list',
        'automation_list',
        'agent_bots',
        'macros_wrapper',
        'canned_list',
        'settings_applications',
        'auditlogs_list',
        'custom_roles_list',
        'sla_list',
        'security_settings_index',
        'branding_settings_index',
        'billing_settings_index',
        'api_docs_index',
      ],
    },
    {
      name: 'API Docs',
      label: t('SIDEBAR.API_DOCS'),
      icon: 'i-lucide-book-open',
      to: accountScopedRoute('api_docs_index'),
      activeOn: ['api_docs_index'],
    },
  ];

  // Retorna menu baseado no role
  if (isAdmin.value) {
    return adminMenu;
  }

  return collaboratorMenu;
});
</script>

<template>
  <aside
    v-on-click-outside="[
      closeMobileSidebar,
      { ignore: ['#mobile-sidebar-launcher'] },
    ]"
    class="bg-white rtl:border-l ltr:border-r border-gray-200 flex flex-col text-sm pb-1 fixed top-0 ltr:left-0 rtl:right-0 h-full z-40 transition-transform duration-200 ease-in-out md:static w-[200px] basis-[200px] md:flex-shrink-0 md:ltr:translate-x-0 md:rtl:-translate-x-0"
    :class="[
      {
        'shadow-lg md:shadow-none': isMobileSidebarOpen,
        'ltr:-translate-x-full rtl:translate-x-full': !isMobileSidebarOpen,
      },
    ]"
  >
    <section class="grid gap-2 mt-2 mb-4">
      <div class="flex gap-2 items-center px-2 min-w-0">
        <div class="grid flex-shrink-0 place-content-center size-6">
          <Logo class="size-4" />
        </div>
        <div class="flex-shrink-0 w-px h-3 bg-n-strong" />
        <SidebarAccountSwitcher
          class="flex-grow -mx-1 min-w-0"
          @show-create-account-modal="emit('showCreateAccountModal')"
        />
      </div>
      <div class="flex gap-2 px-2">
        <RouterLink
          :to="{ name: 'search' }"
          class="flex gap-2 items-center px-2 py-1 w-full h-7 rounded-lg outline outline-1 outline-n-weak bg-n-solid-3 dark:bg-n-black/30"
        >
          <span class="flex-shrink-0 i-lucide-search size-4 text-n-slate-11" />
          <span class="flex-grow text-left">
            {{ t('COMBOBOX.SEARCH_PLACEHOLDER') }}
          </span>
          <span
            class="hidden tracking-wide pointer-events-none select-none text-n-slate-10"
          >
            {{ searchShortcut }}
          </span>
        </RouterLink>
        <ComposeConversation align-position="right" @close="onComposeClose">
          <template #trigger="{ toggle }">
            <Button
              icon="i-lucide-pen-line"
              color="slate"
              size="sm"
              class="!h-7 !bg-n-solid-3 dark:!bg-n-black/30 !outline-n-weak !text-n-slate-11"
              @click="onComposeOpen(toggle)"
            />
          </template>
        </ComposeConversation>
      </div>
    </section>
    <nav class="grid overflow-y-scroll flex-grow gap-2 px-2 pb-5 no-scrollbar">
      <ul class="flex flex-col gap-1.5 m-0 list-none">
        <SidebarGroup
          v-for="item in menuItems"
          :key="item.name"
          v-bind="item"
        />
      </ul>
    </nav>
    <section
      class="flex flex-col flex-shrink-0 relative gap-1 justify-between items-center"
    >
      <div
        class="pointer-events-none absolute inset-x-0 -top-[31px] h-8 bg-gradient-to-t from-white to-transparent"
      />
      <YearInReviewBanner />
      <SidebarChangelogCard
        v-if="isOnChatwootCloud && !isACustomBrandedInstance"
      />
      <div
        class="p-1 flex-shrink-0 flex w-full justify-between z-10 gap-2 items-center border-t border-gray-200"
      >
        <SidebarProfileMenu
          @open-key-shortcut-modal="emit('openKeyShortcutModal')"
        />
      </div>
    </section>
  </aside>
</template>
