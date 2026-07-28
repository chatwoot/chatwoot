<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';

const route = useRoute();
const router = useRouter();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();

const tabs = computed(() => {
  const items = [
    {
      name: 'home',
      icon: 'i-ph-house',
      activeIcon: 'i-ph-house-fill',
      label: 'TABS.HOME',
    },
    {
      name: 'conversations',
      icon: 'i-ph-chat-circle',
      activeIcon: 'i-ph-chat-circle-fill',
      label: 'TABS.MESSAGES',
    },
  ];
  if (configStore.portal) {
    items.push({
      name: 'help',
      icon: 'i-ph-book-open',
      activeIcon: 'i-ph-book-open-fill',
      label: 'TABS.HELP',
    });
  }
  if (configStore.hasAiAgent) {
    items.push({
      name: 'ai',
      icon: 'i-ph-sparkle',
      activeIcon: 'i-ph-sparkle-fill',
      label: 'TABS.AI',
    });
  }
  return items;
});

const isActive = name =>
  route.name === name || route.name?.startsWith(`${name}-`);

const unreadCount = computed(() => conversationsStore.totalUnread);
</script>

<template>
  <nav
    class="flex items-stretch shrink-0 h-16 bar-blur border-t border-cw-hairline"
    :aria-label="$t('TABS.HOME')"
  >
    <button
      v-for="tab in tabs"
      :key="tab.name"
      type="button"
      class="relative flex flex-col items-center justify-center flex-1 gap-1 outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring transition-colors"
      :class="
        isActive(tab.name)
          ? 'text-cw-primary'
          : 'text-cw-text-faint hover:text-cw-text-muted'
      "
      @click="router.push({ name: tab.name })"
    >
      <span class="relative flex items-center justify-center h-6">
        <span
          :class="isActive(tab.name) ? tab.activeIcon : tab.icon"
          class="text-xl"
        />
        <span
          v-if="tab.name === 'conversations' && unreadCount"
          class="absolute -top-1 -right-2.5 min-w-4 h-4 px-1 flex items-center justify-center rounded-full bg-cw-primary text-cw-primary-foreground text-xxs font-semibold ring-2 ring-cw-solid"
        >
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
      </span>
      <span
        class="text-xs tracking-wide"
        :class="isActive(tab.name) ? 'font-520' : 'font-medium'"
      >
        {{ $t(tab.label) }}
      </span>
    </button>
  </nav>
</template>
