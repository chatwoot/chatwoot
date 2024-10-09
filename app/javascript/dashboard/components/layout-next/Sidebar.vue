<script setup>
import { h } from 'vue';
import NavItem from './NavItem.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useKbd } from 'dashboard/composables/utils/useKbd';

const { accountId, currentAccount } = useAccount();

const enableNewConversation = false;
const searchShortcut = useKbd([`$mod`, 'k']);

const channelIcon = icon =>
  h(
    'span',
    {
      class: 'size-4 grid place-content-center rounded-full bg-alpha-2',
    },
    [
      h('div', {
        class: `size-3 bg-radix-slate11 ${icon}`,
      }),
    ]
  );

const menuItems = [
  { name: 'Inbox', icon: 'i-lucide-inbox' },
  {
    name: 'Conversation',
    icon: 'i-lucide-message-circle',
    children: [
      { name: 'All' },
      { name: 'Mine' },
      { name: 'Unassigned' },
      { name: 'Mentions' },
    ],
  },
  {
    name: 'Folders',
    icon: 'i-lucide-folder',
    children: [{ name: 'needs-follow-up' }, { name: 'priority-customers' }],
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
];
</script>

<template>
  <aside
    class="w-48 bg-solid-2 border-r border-radix-slate3 p-2 h-screen flex gap-4 flex-col"
  >
    <section class="grid gap-2 mt-2">
      <button
        id="sidebar-account-switcher"
        :data-account-id="accountId"
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls="account-options"
        class="flex items-center gap-2 justify-between w-full rounded-lg hover:bg-alpha-1"
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
            class="text-sm font-medium leading-5 text-radix-slate12"
            aria-live="polite"
          >
            {{ currentAccount.name }}
          </span>
        </div>

        <span
          aria-hidden="true"
          class="i-lucide-chevron-down size-4 text-radix-slate10"
        />
      </button>
      <div class="gap-2 flex">
        <button
          class="rounded-lg py-1 flex items-center gap-2 px-2 border-weak border bg-solid-3 w-full"
        >
          <span
            class="i-lucide-search size-4 text-radix-slate11 flex-shrink-0"
          />
          <span class="flex-grow text-left">
            {{ 'Search...' }}
          </span>
          <span class="tracking-wide select-none pointer-events-none">
            {{ searchShortcut }}
          </span>
        </button>
        <button
          v-if="enableNewConversation"
          class="rounded-lg py-1 flex items-center gap-2 px-2 border-weak border bg-solid-3 w-full"
        >
          <span
            class="i-lucide-square-pen size-4 text-radix-slate11 flex-shrink-0"
          />
        </button>
      </div>
    </section>
    <nav class="grid gap-2">
      <ul class="grid gap-2 list-none m-0">
        <NavItem
          v-for="item in menuItems"
          :key="item.name"
          v-bind="item"
          class="text-radix-slate11 hover:bg-alpha-2 rounded-lg"
        />
      </ul>
    </nav>
  </aside>
</template>
