<script setup>
import { h, ref, computed, onMounted } from 'vue';
import { provideSidebarContext } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import Avatar from 'dashboard/components/base-next/avatar/Avatar.vue';
import NavGroup from './NavGroup.vue';

const { accountId, currentAccount, accountScopedRoute } = useAccount();
const store = useStore();
const searchShortcut = useKbd([`$mod`, 'k']);
const enableNewConversation = false;

const expandedItem = ref(null);
const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

provideSidebarContext({
  expandedItem,
  setExpandedItem,
});

const channelIcon = inbox => {
  const type = inbox.channel_type;

  const channelTypeIconMap = {
    'Channel::Api': 'i-ri-cloudy-fill',
    'Channel::Email': 'i-ri-mail-fill',
    'Channel::FacebookPage': 'i-ri-messenger-fill',
    'Channel::Line': 'i-ri-line-fill',
    'Channel::Sms': 'i-ri-chat-1-fill',
    'Channel::Telegram': 'i-ri-telegram-fill',
    'Channel::TwilioSms': 'i-ri-chat-1-fill',
    'Channel::TwitterProfile': 'i-ri-twitter-x-fill',
    'Channel::WebWidget': 'i-ri-global-fill',
    'Channel::Whatsapp': 'i-ri-whatsapp-fill',
  };

  const providerIconMap = {
    microsoft: 'i-ri-microsoft-fill',
    google: 'i-ri-google-fill',
  };

  let icon = channelTypeIconMap[type];

  if (type === 'Channel::Email' && inbox.provider) {
    if (Object.keys(providerIconMap).includes(inbox.provider)) {
      icon = providerIconMap[inbox.provider];
    }
  }

  return h(
    'span',
    {
      class: 'size-4 grid place-content-center rounded-full',
    },
    [
      h('div', {
        class: `size-3 bg-current ${icon ?? 'i-ri-global-fill'}`,
      }),
    ]
  );
};

const labelIcon = backgroundColor =>
  h('span', {
    class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm`,
    style: { backgroundColor },
  });

const inboxes = useMapGetter('inboxes/getInboxes');
const labels = useMapGetter('labels/getLabelsOnSidebar');
const currentUser = useMapGetter('getCurrentUser');
// const contactCustomViews = useMapGetter('customViews/getContactCustomViews');
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

const menuItems = computed(() => [
  {
    name: 'Inbox',
    icon: 'i-lucide-inbox',
    to: accountScopedRoute('inbox_view'),
  },
  {
    name: 'Conversation',
    icon: 'i-lucide-message-circle',
    children: [
      { name: 'All', to: accountScopedRoute('home') },
      { name: 'Mentions', to: accountScopedRoute('conversation_mentions') },
      { name: 'Unattended', to: accountScopedRoute('conversation_unattended') },
      {
        name: 'Folders',
        icon: 'i-lucide-folder',
        children: conversationCustomViews.value.map(view => ({
          name: view.name,
          to: accountScopedRoute('folder_conversations', { id: view.id }),
        })),
      },
      {
        name: 'Channels',
        icon: 'i-lucide-mailbox',
        children: inboxes.value
          .map(inbox => ({
            name: inbox.name,
            icon: channelIcon(inbox),
            to: accountScopedRoute('inbox_dashboard', { inbox_id: inbox.id }),
            // reauthorizationRequired: inbox.reauthorization_required,
          }))
          .sort((a, b) =>
            a.name.toLowerCase() > b.name.toLowerCase() ? 1 : -1
          ),
      },
      {
        name: 'Labels',
        icon: 'i-lucide-tag',
        children: labels.value.map(label => ({
          name: label.title,
          icon: labelIcon(label.color),
          to: accountScopedRoute('label_conversations', { label: label.title }),
        })),
      },
    ],
  },
  { name: 'Captain', icon: 'i-lucide-bot', to: accountScopedRoute('captain') },
  { name: 'Contacts', icon: 'i-lucide-contact' },
  { name: 'Reports', icon: 'i-lucide-chart-spline' },
  { name: 'Campaigns', icon: 'i-lucide-megaphone' },
  { name: 'Portals', icon: 'i-lucide-library-big' },
  { name: 'Settings', icon: 'i-lucide-bolt' },
]);
</script>

<template>
  <aside
    class="w-48 bg-n-solid-2 border-r border-n-weak h-screen flex flex-col text-sm pt-2"
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
            class="text-sm font-medium leading-5 text-n-slate-12"
            aria-live="polite"
          >
            {{ currentAccount.name }}
          </span>
        </div>

        <span
          aria-hidden="true"
          class="i-lucide-chevron-down size-4 text-n-slate-10"
        />
      </button>
      <div class="gap-2 flex">
        <RouterLink
          :to="{ name: 'search' }"
          class="rounded-lg py-1 flex items-center gap-2 px-2 border-n-weak border bg-n-solid-3 dark:bg-n-black/30 w-full"
        >
          <span class="i-lucide-search size-4 text-n-slate-11 flex-shrink-0" />
          <span class="flex-grow text-left">
            {{ 'Search...' }}
          </span>
          <span
            class="tracking-wide select-none pointer-events-none text-n-slate-10"
          >
            {{ searchShortcut }}
          </span>
        </RouterLink>
        <button
          v-if="enableNewConversation"
          class="rounded-lg py-1 flex items-center gap-2 px-2 border-n-weak border bg-n-solid-3 w-full"
        >
          <span
            class="i-lucide-square-pen size-4 text-n-slate-11 flex-shrink-0"
          />
        </button>
      </div>
    </section>
    <nav class="grid gap-2 overflow-y-scroll no-scrollbar px-2 flex-grow">
      <ul class="flex flex-col gap-2 list-none m-0">
        <NavGroup v-for="item in menuItems" :key="item.name" v-bind="item" />
      </ul>
    </nav>
    <section
      class="px-4 py-3 border-t border-n-weak shadow-[0px_-2px_4px_0px_rgba(27,28,29,0.02)] overflow-x-hidden flex-shrink-0 flex gap-3 items-center"
    >
      <Avatar
        :name="currentUser.available_name"
        :src="currentUser.avatar_url"
      />
      <div class="grid">
        <span class="text-n-slate-12 text-sm leading-5 font-medium">
          {{ currentUser.available_name }}
        </span>
        <span class="text-n-slate-11 leading-4 text-xs">
          {{ currentUser.email }}
        </span>
      </div>
    </section>
  </aside>
</template>
