<script setup>
import { h, ref, computed } from 'vue';
import { provideSidebarContext } from './provider';
import NavItem from './NavItem.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import Avatar from 'dashboard/components/base-next/avatar/Avatar.vue';
import { useKbd } from 'dashboard/composables/utils/useKbd';

const { accountId, currentAccount, accountScopedRoute } = useAccount();

const enableNewConversation = false;
const searchShortcut = useKbd([`$mod`, 'k']);

const expandedItem = ref(null);
const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

provideSidebarContext({
  expandedItem,
  setExpandedItem,
});

const channelIcon = icon =>
  h(
    'span',
    {
      class: 'size-4 grid place-content-center rounded-full bg-n-alpha-2',
    },
    [
      h('div', {
        class: `size-3 bg-n-slate11 ${icon}`,
      }),
    ]
  );

const labelIcon = backgroundColor =>
  h('span', {
    class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm`,
    style: { backgroundColor },
  });

const menuItems = computed(() => [
  {
    name: 'Inbox',
    icon: 'i-lucide-inbox',
    to: accountScopedRoute('inbox_view'),
  },
  {
    name: 'Conversation',
    icon: 'i-lucide-message-circle',
    to: accountScopedRoute('home'),
    children: [
      { name: 'All', to: accountScopedRoute('home') },
      { name: 'Mine', to: accountScopedRoute('home') },
      { name: 'Unassigned', to: accountScopedRoute('home') },
      { name: 'Mentions', to: accountScopedRoute('home') },
    ],
  },
  {
    name: 'Folders',
    icon: 'i-lucide-folder',
    children: [{ name: 'needs-follow-up' }, { name: 'priority-customers' }],
  },
  {
    name: 'Labels',
    icon: 'i-lucide-tag',
    children: [
      {
        name: 'americas',
        icon: labelIcon('#059669'),
        to: accountScopedRoute('label_conversations', { label: 'americas' }),
      },
      {
        name: 'apac',
        icon: labelIcon('#115e59'),
        to: accountScopedRoute('label_conversations', { label: 'apac' }),
      },
      {
        name: 'billing',
        icon: labelIcon('#1d4ed8'),
        to: accountScopedRoute('label_conversations', { label: 'billing' }),
      },
      {
        name: 'bug',
        icon: labelIcon('#500724'),
        to: accountScopedRoute('label_conversations', { label: 'bug' }),
      },
      {
        name: 'europe',
        icon: labelIcon('#65a30d'),
        to: accountScopedRoute('label_conversations', { label: 'europe' }),
      },
      {
        name: 'feature-request',
        icon: labelIcon('#6d28d9'),
        to: accountScopedRoute('label_conversations', {
          label: 'feature-request',
        }),
      },
      {
        name: 'marketing',
        icon: labelIcon('#7dd3fc'),
        to: accountScopedRoute('label_conversations', { label: 'marketing' }),
      },
      {
        name: 'other',
        icon: labelIcon('#bef264'),
        to: accountScopedRoute('label_conversations', { label: 'other' }),
      },
      {
        name: 'refund',
        icon: labelIcon('#dc2626'),
        to: accountScopedRoute('label_conversations', { label: 'refund' }),
      },
      {
        name: 'sales',
        icon: labelIcon('#f87171'),
        to: accountScopedRoute('label_conversations', { label: 'sales' }),
      },
      {
        name: 'sea',
        icon: labelIcon('#fb923c'),
        to: accountScopedRoute('label_conversations', { label: 'sea' }),
      },
      {
        name: 'software',
        icon: labelIcon('#fbbf24'),
        to: accountScopedRoute('label_conversations', { label: 'software' }),
      },
      {
        name: 'spam',
        icon: labelIcon('#fbbf24'),
        to: accountScopedRoute('label_conversations', { label: 'spam' }),
      },
      {
        name: 'support',
        icon: labelIcon('#fcd34d'),
        to: accountScopedRoute('label_conversations', { label: 'support' }),
      },
    ],
  },
  {
    name: 'Channels',
    icon: 'i-lucide-mailbox',
    children: [
      {
        name: 'Website',
        icon: channelIcon('i-ri-global-fill'),
      },
      {
        name: 'Facebook',
        icon: channelIcon('i-ri-messenger-fill'),
      },
      {
        name: 'WhatsApp',
        icon: channelIcon('i-ri-whatsapp-fill'),
      },
    ],
  },
  { name: 'Captain', icon: 'i-lucide-bot' },
  { name: 'Contacts', icon: 'i-lucide-contact' },
  { name: 'Reports', icon: 'i-lucide-chart-spline' },
  { name: 'Campaigns', icon: 'i-lucide-megaphone' },
  { name: 'Portals', icon: 'i-lucide-library-big' },
  { name: 'Settings', icon: 'i-lucide-bolt' },
]);
</script>

<template>
  <aside
    class="w-48 bg-n-solid-2 border-r border-n-slate3 h-screen flex flex-col text-sm pt-2"
  >
    <section class="grid gap-2 mt-2 px-2 mb-4">
      <button
        id="sidebar-account-switcher"
        :data-account-id="accountId"
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls="account-options"
        class="flex items-center gap-2 justify-between w-full rounded-lg hover:bg-n-alpha-1"
      >
        <div class="flex items-center gap-2">
          <span class="size-4">
            <img
              class="size-4"
              :alt="`Account logo for ${currentAccount.name}`"
              aria-hidden="true"
              src="https://app.chatwoot.com/brand-assets/logo_thumbnail.svg"
            />
          </span>
          <span
            class="text-sm font-medium leading-5 text-n-slate12"
            aria-live="polite"
          >
            {{ currentAccount.name }}
          </span>
        </div>

        <span
          aria-hidden="true"
          class="i-lucide-chevron-down size-4 text-n-slate10"
        />
      </button>
      <div class="gap-2 flex">
        <button
          class="rounded-lg py-1 flex items-center gap-2 px-2 border-n-weak border bg-n-solid-3 w-full"
        >
          <span class="i-lucide-search size-4 text-n-slate11 flex-shrink-0" />
          <span class="flex-grow text-left">
            {{ 'Search...' }}
          </span>
          <span
            class="tracking-wide select-none pointer-events-none text-n-slate10"
          >
            {{ searchShortcut }}
          </span>
        </button>
        <button
          v-if="enableNewConversation"
          class="rounded-lg py-1 flex items-center gap-2 px-2 border-n-weak border bg-n-solid-3 w-full"
        >
          <span
            class="i-lucide-square-pen size-4 text-n-slate11 flex-shrink-0"
          />
        </button>
      </div>
    </section>
    <nav class="grid gap-2 overflow-y-scroll no-scrollbar px-2 flex-grow">
      <ul class="flex flex-col gap-2 list-none m-0">
        <NavItem v-for="item in menuItems" :key="item.name" v-bind="item" />
      </ul>
    </nav>
    <section
      class="px-4 py-3 border-t border-n-weak shadow-[0px_-2px_4px_0px_rgba(27,28,29,0.02)] overflow-x-hidden flex-shrink-0"
    >
      <Avatar name="Shivam Mishra" />
    </section>
  </aside>
</template>
