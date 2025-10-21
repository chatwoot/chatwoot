<script setup>
import { h, computed, onMounted, onUnmounted } from 'vue';
import { provideSidebarContext } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useStorage } from '@vueuse/core';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import SidebarGroup from './SidebarGroup.vue';
import SidebarProfileMenu from './SidebarProfileMenu.vue';
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

const { accountScopedRoute } = useAccount();
const store = useStore();
const searchShortcut = useKbd([`$mod`, 'k']);
const { t } = useI18n();

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
const totalUnreadCount = useMapGetter('getTotalUnreadCount');
const getUnreadCountForLabel = useMapGetter('getUnreadCountForLabel');
const getUnreadCountForTeam = useMapGetter('getUnreadCountForTeam');
// Removed unused custom views - simplified for poker operator UI
const refreshCounts = async () => {
  await store.dispatch('fetchAllConversationsForCounts');
};
onMounted(async () => {
  await Promise.all([
    store.dispatch('labels/get'),
    store.dispatch('inboxes/get'),
    store.dispatch('notifications/unReadCount'),
    store.dispatch('teams/get'),
    store.dispatch('attributes/get'),
    store.dispatch('customViews/get', 'conversation'),
    store.dispatch('customViews/get', 'contact'),
    store.dispatch('macros/get'),
    // Load all conversations for sidebar counts
    store.dispatch('fetchAllConversationsForCounts'),
  ]);
  // Refresh counts when conversations are updated
  emitter.on(BUS_EVENTS.WEBSOCKET_RECONNECT, refreshCounts);
  emitter.on('fetch_conversation_stats', refreshCounts);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.WEBSOCKET_RECONNECT, refreshCounts);
  emitter.off('fetch_conversation_stats', refreshCounts);
});

const sortedInboxes = computed(() =>
  inboxes.value.slice().sort((a, b) => a.name.localeCompare(b.name))
);

const closeMobileSidebar = () => {
  if (!props.isMobileSidebarOpen) return;
  emit('closeMobileSidebar');
};

const menuItems = computed(() => {
  return [
    {
      name: 'TodoList',
      label: t('TODO.TITLE'),
      icon: 'i-lucide-list-todo',
      to: accountScopedRoute('todo_list'),
      activeOn: ['todo_list'],
    },
    {
      name: 'Conversation',
      label: t('SIDEBAR.CONVERSATIONS'),
      icon: 'i-lucide-message-circle',
      children: [
        {
          name: 'All',
          label: t('SIDEBAR.ALL_CONVERSATIONS'),
          activeOn: ['inbox_conversation'],
          to: accountScopedRoute('home'),
        },
        {
          name: 'Unattended',
          activeOn: ['conversation_through_unattended'],
          label: t('SIDEBAR.UNATTENDED_CONVERSATIONS'),
          to: accountScopedRoute('conversation_unattended'),
          count: totalUnreadCount.value || 0,
        },
        {
          name: 'Mentions',
          label: t('SIDEBAR.MENTIONED_CONVERSATIONS'),
          activeOn: ['conversation_through_mentions'],
          to: accountScopedRoute('conversation_mentions'),
        },
        {
          name: 'Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          activeOn: ['conversations_through_team'],
          children: teams.value.map(team => {
            const unreadCount = getUnreadCountForTeam.value(team.id);
            return {
              name: `${team.name}-${team.id}`,
              label: team.name,
              count: unreadCount,
              to: accountScopedRoute('team_conversations', { teamId: team.id }),
            };
          }),
        },
        {
          name: 'Channels',
          label: t('SIDEBAR.CHANNELS'),
          icon: 'i-lucide-mailbox',
          activeOn: ['conversation_through_inbox'],
          children: sortedInboxes.value.map(inbox => ({
            name: `${inbox.name}-${inbox.id}`,
            label: inbox.name,
            to: accountScopedRoute('inbox_dashboard', { inbox_id: inbox.id }),
            component: leafProps =>
              h(ChannelLeaf, {
                label: leafProps.label,
                active: leafProps.active,
                inbox,
              }),
          })),
        },
        {
          name: 'Labels',
          label: t('SIDEBAR.LABELS'),
          icon: 'i-lucide-tag',
          activeOn: ['conversations_through_label'],
          children: labels.value.map(label => {
            const unreadCount = getUnreadCountForLabel.value(label.title);
            return {
              name: `${label.title}-${label.id}`,
              label: label.title,
              count: unreadCount,
              icon: h('span', {
                class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm`,
                style: { backgroundColor: label.color },
              }),
              to: accountScopedRoute('label_conversations', {
                label: label.title,
              }),
              component: leafProps =>
                h('div', { class: 'flex items-center gap-2 flex-1 min-w-0' }, [
                  h('span', {
                    class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm flex-shrink-0`,
                    style: { backgroundColor: label.color },
                  }),
                  h(
                    'div',
                    { class: 'flex-1 truncate min-w-0' },
                    leafProps.label
                  ),
                  leafProps.count > 0
                    ? h(
                        'span',
                        {
                          class:
                            'ml-auto text-xs font-semibold px-1.5 py-0.5 rounded bg-red-500 text-white',
                        },
                        leafProps.count > 99 ? '99+' : leafProps.count
                      )
                    : null,
                ]),
            };
          }),
        },
      ],
    },
    {
      name: 'Settings',
      label: t('SIDEBAR.SETTINGS'),
      icon: 'i-lucide-bolt',
      children: [
        {
          name: 'Settings Account Settings',
          label: t('SIDEBAR.ACCOUNT_SETTINGS'),
          icon: 'i-lucide-briefcase',
          to: accountScopedRoute('general_settings_index'),
        },
        {
          name: 'Settings Agents',
          label: t('SIDEBAR.AGENTS'),
          icon: 'i-lucide-square-user',
          to: accountScopedRoute('agent_list'),
        },
        {
          name: 'Settings Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          to: accountScopedRoute('settings_teams_list'),
        },
        {
          name: 'Settings Agent Assignment',
          label: t('SIDEBAR.AGENT_ASSIGNMENT'),
          icon: 'i-lucide-user-cog',
          to: accountScopedRoute('assignment_policy_index'),
        },
        {
          name: 'Settings Inboxes',
          label: t('SIDEBAR.INBOXES'),
          icon: 'i-lucide-inbox',
          to: accountScopedRoute('settings_inbox_list'),
        },
        {
          name: 'Settings Labels',
          label: t('SIDEBAR.LABELS'),
          icon: 'i-lucide-tags',
          to: accountScopedRoute('labels_list'),
        },
        {
          name: 'Settings Custom Attributes',
          label: t('SIDEBAR.CUSTOM_ATTRIBUTES'),
          icon: 'i-lucide-code',
          to: accountScopedRoute('attributes_list'),
        },
        {
          name: 'Settings Automation',
          label: t('SIDEBAR.AUTOMATION'),
          icon: 'i-lucide-workflow',
          to: accountScopedRoute('automation_list'),
        },
        {
          name: 'Settings Agent Bots',
          label: t('SIDEBAR.AGENT_BOTS'),
          icon: 'i-lucide-bot',
          to: accountScopedRoute('agent_bots'),
        },
        {
          name: 'Settings Macros',
          label: t('SIDEBAR.MACROS'),
          icon: 'i-lucide-toy-brick',
          to: accountScopedRoute('macros_wrapper'),
        },
        {
          name: 'Settings Canned Responses',
          label: t('SIDEBAR.CANNED_RESPONSES'),
          icon: 'i-lucide-message-square-quote',
          to: accountScopedRoute('canned_list'),
        },
        {
          name: 'Settings Integrations',
          label: t('SIDEBAR.INTEGRATIONS'),
          icon: 'i-lucide-blocks',
          to: accountScopedRoute('settings_applications'),
        },
        {
          name: 'Settings Audit Logs',
          label: t('SIDEBAR.AUDIT_LOGS'),
          icon: 'i-lucide-briefcase',
          to: accountScopedRoute('auditlogs_list'),
        },
        {
          name: 'Settings Custom Roles',
          label: t('SIDEBAR.CUSTOM_ROLES'),
          icon: 'i-lucide-shield-plus',
          to: accountScopedRoute('custom_roles_list'),
        },
        {
          name: 'Settings Sla',
          label: t('SIDEBAR.SLA'),
          icon: 'i-lucide-clock-alert',
          to: accountScopedRoute('sla_list'),
        },
        {
          name: 'Settings Security',
          label: t('SIDEBAR.SECURITY'),
          icon: 'i-lucide-shield',
          to: accountScopedRoute('security_settings_index'),
        },
        {
          name: 'Settings Billing',
          label: t('SIDEBAR.BILLING'),
          icon: 'i-lucide-credit-card',
          to: accountScopedRoute('billing_settings_index'),
        },
      ],
    },
  ];
});
</script>

<template>
  <aside
    v-on-click-outside="[
      closeMobileSidebar,
      { ignore: ['#mobile-sidebar-launcher'] },
    ]"
    class="bg-n-solid-2 rtl:border-l ltr:border-r border-n-weak flex flex-col text-sm pb-1 fixed top-0 ltr:left-0 rtl:right-0 h-full z-40 transition-transform duration-200 ease-in-out md:static w-[200px] basis-[200px] md:flex-shrink-0 md:ltr:translate-x-0 md:rtl:-translate-x-0"
    :class="[
      {
        'shadow-lg md:shadow-none': isMobileSidebarOpen,
        'ltr:-translate-x-full rtl:translate-x-full': !isMobileSidebarOpen,
      },
    ]"
  >
    <section class="grid gap-2 mt-2 mb-4">
      <div class="flex items-center min-w-0 gap-2 px-2">
        <div class="grid flex-shrink-0 size-6 place-content-center">
          <Logo class="size-4" />
        </div>
        <div class="flex-shrink-0 w-px h-3 bg-n-strong" />
        <SidebarAccountSwitcher
          class="flex-grow min-w-0 -mx-1"
          @show-create-account-modal="emit('showCreateAccountModal')"
        />
      </div>
      <div class="flex gap-2 px-2">
        <RouterLink
          :to="{ name: 'search' }"
          class="flex items-center w-full gap-2 px-2 py-1 rounded-lg h-7 outline outline-1 outline-n-weak bg-n-solid-3 dark:bg-n-black/30"
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
        <ComposeConversation align-position="right">
          <template #trigger="{ toggle }">
            <Button
              icon="i-lucide-pen-line"
              color="slate"
              size="sm"
              class="!h-7 !bg-n-solid-3 dark:!bg-n-black/30 !outline-n-weak !text-n-slate-11"
              @click="toggle"
            />
          </template>
        </ComposeConversation>
      </div>
    </section>
    <nav class="grid flex-grow gap-2 px-2 pb-5 overflow-y-scroll no-scrollbar">
      <ul class="flex flex-col gap-1.5 m-0 list-none">
        <SidebarGroup
          v-for="item in menuItems"
          :key="item.name"
          v-bind="item"
        />
      </ul>
    </nav>
    <section
      class="p-1 border-t border-n-weak shadow-[0px_-2px_4px_0px_rgba(27,28,29,0.02)] flex-shrink-0 flex justify-between gap-2 items-center"
    >
      <SidebarProfileMenu
        @open-key-shortcut-modal="emit('openKeyShortcutModal')"
      />
    </section>
  </aside>
</template>
