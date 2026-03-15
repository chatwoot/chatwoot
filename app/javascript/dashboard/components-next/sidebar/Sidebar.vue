<script setup>
import { h, ref, computed, onMounted } from 'vue';
import { provideSidebarContext, useSidebarResize } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import { vOnClickOutside } from '@vueuse/components';
import { useWindowSize } from '@vueuse/core';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

import Button from 'dashboard/components-next/button/Button.vue';
import SidebarGroup from './SidebarGroup.vue';
import SidebarProfileMenu from './SidebarProfileMenu.vue';
import SidebarChangelogCard from './SidebarChangelogCard.vue';
import SidebarChangelogButton from './SidebarChangelogButton.vue';
import ChannelLeaf from './ChannelLeaf.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
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

const isACustomBrandedInstance = useMapGetter(
  'globalConfig/isACustomBrandedInstance'
);
const isRTL = useMapGetter('accounts/isRTL');

const { width: windowWidth } = useWindowSize();
const isMobile = computed(() => windowWidth.value < 768);

const toggleShortcutModalFn = show => {
  if (show) {
    emit('openKeyShortcutModal');
  } else {
    emit('closeKeyShortcutModal');
  }
};

useSidebarKeyboardShortcuts(toggleShortcutModalFn);

const expandedItem = ref(null);

const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

const { MIN_WIDTH } = useSidebarResize();

const HOVER_EXPANDED_WIDTH = 240;
const isHovered = ref(false);
const sidebarWidth = computed(() => isHovered.value ? HOVER_EXPANDED_WIDTH : MIN_WIDTH);
const isCollapsed = computed(() => !isHovered.value);

// On mobile, sidebar is always expanded (flyout mode)
const isEffectivelyCollapsed = computed(
  () => !isMobile.value && isCollapsed.value
);

provideSidebarContext({
  expandedItem,
  setExpandedItem,
  isCollapsed: isEffectivelyCollapsed,
  sidebarWidth,
  isResizing: ref(false),
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

const menuItems = computed(() => {
  return [
    {
      name: 'Inbox',
      label: t('SIDEBAR.INBOX'),
      icon: 'i-lucide-inbox',
      to: accountScopedRoute('inbox_view'),
      activeOn: ['inbox_view', 'inbox_view_conversation'],
      getterKeys: {
        count: 'notifications/getUnreadCount',
      },
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
          name: 'Mentions',
          label: t('SIDEBAR.MENTIONED_CONVERSATIONS'),
          activeOn: ['conversation_through_mentions'],
          to: accountScopedRoute('conversation_mentions'),
        },
        {
          name: 'Unattended',
          activeOn: ['conversation_through_unattended'],
          label: t('SIDEBAR.UNATTENDED_CONVERSATIONS'),
          to: accountScopedRoute('conversation_unattended'),
        },
        {
          name: 'Folders',
          label: t('SIDEBAR.CUSTOM_VIEWS_FOLDER'),
          icon: 'i-lucide-folder',
          activeOn: ['conversations_through_folders'],
          children: conversationCustomViews.value.map(view => ({
            name: `${view.name}-${view.id}`,
            label: view.name,
            to: accountScopedRoute('folder_conversations', { id: view.id }),
          })),
        },
        {
          name: 'Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          activeOn: ['conversations_through_team'],
          children: teams.value.map(team => ({
            name: `${team.name}-${team.id}`,
            label: team.name,
            to: accountScopedRoute('team_conversations', { teamId: team.id }),
          })),
        },
        {
          name: 'Channels',
          label: t('SIDEBAR.CHANNELS'),
          icon: 'i-lucide-mailbox',
          activeOn: ['conversation_through_inbox'],
          children: sortedInboxes.value.map(inbox => ({
            name: `${inbox.name}-${inbox.id}`,
            label: inbox.name,
            icon: h(ChannelIcon, { inbox, class: 'size-[16px]' }),
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
          children: labels.value.map(label => ({
            name: `${label.title}-${label.id}`,
            label: label.title,
            icon: h('span', {
              class: `size-[8px] rounded-sm`,
              style: { backgroundColor: label.color },
            }),
            to: accountScopedRoute('label_conversations', {
              label: label.title,
            }),
          })),
        },
      ],
    },
    {
      name: 'Contacts',
      label: t('SIDEBAR.CONTACTS'),
      icon: 'i-lucide-contact',
      children: [
        {
          name: 'All Contacts',
          label: t('SIDEBAR.ALL_CONTACTS'),
          to: accountScopedRoute(
            'contacts_dashboard_index',
            {},
            { page: 1, search: undefined }
          ),
          activeOn: ['contacts_dashboard_index', 'contacts_edit'],
        },
        {
          name: 'Active',
          label: t('SIDEBAR.ACTIVE'),
          to: accountScopedRoute('contacts_dashboard_active'),
          activeOn: ['contacts_dashboard_active'],
        },
        {
          name: 'Segments',
          icon: 'i-lucide-group',
          label: t('SIDEBAR.CUSTOM_VIEWS_SEGMENTS'),
          children: contactCustomViews.value.map(view => ({
            name: `${view.name}-${view.id}`,
            label: view.name,
            to: accountScopedRoute(
              'contacts_dashboard_segments_index',
              { segmentId: view.id },
              { page: 1 }
            ),
            activeOn: [
              'contacts_dashboard_segments_index',
              'contacts_edit_segment',
            ],
          })),
        },
        {
          name: 'Tagged With',
          icon: 'i-lucide-tag',
          label: t('SIDEBAR.TAGGED_WITH'),
          children: labels.value.map(label => ({
            name: `${label.title}-${label.id}`,
            label: label.title,
            icon: h('span', {
              class: `size-[8px] rounded-sm`,
              style: { backgroundColor: label.color },
            }),
            to: accountScopedRoute(
              'contacts_dashboard_labels_index',
              { label: label.title },
              { page: 1, search: undefined }
            ),
            activeOn: [
              'contacts_dashboard_labels_index',
              'contacts_edit_label',
            ],
          })),
        },
      ],
    },
    {
      name: 'Reports',
      label: t('SIDEBAR.REPORTS'),
      icon: 'i-lucide-chart-spline',
      children: [
        {
          name: 'Report Overview',
          label: t('SIDEBAR.REPORTS_OVERVIEW'),
          to: accountScopedRoute('account_overview_reports'),
        },
        {
          name: 'Report Conversation',
          label: t('SIDEBAR.REPORTS_CONVERSATION'),
          to: accountScopedRoute('conversation_reports'),
        },
        ...reportRoutes.value,
        {
          name: 'Reports CSAT',
          label: t('SIDEBAR.CSAT'),
          to: accountScopedRoute('csat_reports'),
        },
        {
          name: 'Reports Bot',
          label: t('SIDEBAR.REPORTS_BOT'),
          to: accountScopedRoute('bot_reports'),
        },
      ],
    },
    {
      name: 'Campaigns',
      label: t('SIDEBAR.CAMPAIGNS'),
      icon: 'i-lucide-megaphone',
      children: [
        {
          name: 'Live chat',
          label: t('SIDEBAR.LIVE_CHAT'),
          to: accountScopedRoute('campaigns_livechat_index'),
        },
        {
          name: 'WhatsApp',
          label: t('SIDEBAR.WHATSAPP'),
          to: accountScopedRoute('campaigns_whatsapp_index'),
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
        // {
        //   name: 'Settings Captain',
        //   label: t('SIDEBAR.CAPTAIN_AI'),
        //   icon: 'i-woot-captain',
        //   to: accountScopedRoute('captain_settings_index'),
        // },
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
          activeOn: [
            'settings_teams_list',
            'settings_teams_new',
            'settings_teams_finish',
            'settings_teams_add_agents',
            'settings_teams_show',
            'settings_teams_edit',
            'settings_teams_edit_members',
            'settings_teams_edit_finish',
          ],
          to: accountScopedRoute('settings_teams_list'),
        },
        {
          name: 'Settings Inboxes',
          label: t('SIDEBAR.INBOXES'),
          icon: 'i-lucide-inbox',
          activeOn: [
            'settings_inbox_list',
            'settings_inbox_show',
            'settings_inbox_new',
            'settings_inbox_finish',
            'settings_inboxes_page_channel',
            'settings_inboxes_add_agents',
          ],
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
          icon: 'i-lucide-repeat',
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
    class="flex flex-col text-sm pb-px fixed top-10 ltr:left-0 rtl:right-0 bottom-0 z-40 w-[200px] ltr:border-r rtl:border-l border-[rgba(45,56,71,0.3)] transition-all duration-200 ease-out"
    :class="[
      {
        'shadow-lg': isMobileSidebarOpen,
        'shadow-[4px_0_20px_rgba(0,0,0,0.3)]': !isMobile && !isEffectivelyCollapsed,
        'ltr:-translate-x-full rtl:translate-x-full md:ltr:translate-x-0 md:rtl:translate-x-0': !isMobileSidebarOpen,
      },
    ]"
    :style="[
      { background: 'rgba(14,17,28,0.92)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)' },
      isMobile ? undefined : { width: sidebarWidth + 'px' },
    ]"
    @mouseenter="isHovered = true"
    @mouseleave="isHovered = false"
  >
    <section
      class="grid"
      :class="isEffectivelyCollapsed ? 'mt-3 mb-6 gap-4' : 'mt-1 mb-4 gap-2'"
    >
      <div
        class="flex gap-2 items-center min-w-0"
        :class="{
          'justify-center px-1': isEffectivelyCollapsed,
          'px-2': !isEffectivelyCollapsed,
        }"
      >
        <template v-if="isEffectivelyCollapsed">
          <SidebarAccountSwitcher
            is-collapsed
            @show-create-account-modal="emit('showCreateAccountModal')"
          />
        </template>
        <template v-else>
          <div class="grid flex-shrink-0 place-content-center size-6">
            <Logo class="size-4" />
          </div>
          <div class="flex-shrink-0 w-px h-3 bg-n-strong" />
          <SidebarAccountSwitcher
            class="flex-grow -mx-1 min-w-0"
            @show-create-account-modal="emit('showCreateAccountModal')"
          />
        </template>
      </div>
      <div
        class="flex gap-2"
        :class="isEffectivelyCollapsed ? 'flex-col items-center' : 'px-2'"
      >
        <RouterLink
          v-if="!isEffectivelyCollapsed"
          :to="{ name: 'search' }"
          class="flex gap-2 items-center px-2 py-1 w-full h-7 rounded-lg outline outline-1 outline-n-weak bg-n-button-color transition-all duration-100 ease-out"
        >
          <span class="flex-shrink-0 i-lucide-search size-4 text-n-slate-10" />
          <span class="flex-grow text-start text-n-slate-10">
            {{ t('COMBOBOX.SEARCH_PLACEHOLDER') }}
          </span>
          <span
            class="hidden tracking-wide pointer-events-none select-none text-n-slate-10"
          >
            {{ searchShortcut }}
          </span>
        </RouterLink>
        <RouterLink
          v-else
          :to="{ name: 'search' }"
          class="flex items-center justify-center size-8 rounded-lg outline outline-1 outline-n-weak bg-n-button-color transition-all duration-100 ease-out hover:bg-n-alpha-2 dark:hover:bg-n-slate-9/30"
          :title="t('COMBOBOX.SEARCH_PLACEHOLDER')"
        >
          <span class="i-lucide-search size-4 text-n-slate-11" />
        </RouterLink>
        <ComposeConversation align-position="right" @close="onComposeClose">
          <template #trigger="{ toggle, isOpen }">
            <Button
              icon="i-lucide-pen-line"
              color="slate"
              size="sm"
              class="dark:hover:!bg-n-slate-9/30"
              :class="[
                isEffectivelyCollapsed
                  ? '!size-8 !outline-n-weak !text-n-slate-11'
                  : '!h-7 !outline-n-weak !text-n-slate-11',
                { '!bg-n-alpha-2 dark:!bg-n-slate-9/30': isOpen },
              ]"
              @click="onComposeOpen(toggle)"
            />
          </template>
        </ComposeConversation>
      </div>
    </section>
    <nav
      class="grid overflow-y-scroll flex-grow gap-2 pb-5 no-scrollbar min-w-0"
      :class="isEffectivelyCollapsed ? 'px-1' : 'px-2'"
    >
      <ul
        class="flex flex-col gap-1 m-0 list-none min-w-0"
        :class="{ 'items-center': isEffectivelyCollapsed }"
      >
        <SidebarGroup
          v-for="item in menuItems"
          :key="item.name"
          v-bind="item"
        />
      </ul>
    </nav>
    <section
      class="flex relative flex-col flex-shrink-0 gap-1 justify-between items-center"
    >
      <div
        class="pointer-events-none absolute inset-x-0 -top-[1.938rem] h-8 bg-gradient-to-t from-n-background to-transparent"
      />
      <SidebarChangelogCard
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          !isEffectivelyCollapsed
        "
      />
      <SidebarChangelogButton
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          isEffectivelyCollapsed
        "
      />
      <div
        class="px-1 py-1.5 flex-shrink-0 flex w-full z-50 gap-2 items-center border-t border-n-weak shadow-[0px_-2px_4px_0px_rgba(27,28,29,0.02)]"
        :class="isEffectivelyCollapsed ? 'justify-center' : 'justify-between'"
      >
        <SidebarProfileMenu
          :is-collapsed="isEffectivelyCollapsed"
          @open-key-shortcut-modal="emit('openKeyShortcutModal')"
        />
      </div>
    </section>
  </aside>
</template>
