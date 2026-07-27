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
    { name: 'home', icon: 'i-lucide-house', label: 'TABS.HOME' },
    {
      name: 'conversations',
      icon: 'i-lucide-message-circle',
      label: 'TABS.MESSAGES',
    },
  ];
  if (configStore.portal) {
    items.push({
      name: 'help',
      icon: 'i-lucide-book-open',
      label: 'TABS.HELP',
    });
  }
  if (configStore.hasAiAgent) {
    items.push({ name: 'ai', icon: 'i-lucide-sparkles', label: 'TABS.AI' });
  }
  return items;
});

const isActive = name =>
  route.name === name || route.name?.startsWith(`${name}-`);

const unreadCount = computed(() => conversationsStore.totalUnread);
</script>

<template>
  <nav
    class="flex items-stretch shrink-0 h-16 bg-cw-background border-t border-cw-border"
    :aria-label="$t('TABS.HOME')"
  >
    <button
      v-for="tab in tabs"
      :key="tab.name"
      type="button"
      class="relative flex flex-col items-center justify-center flex-1 gap-1 outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cw-primary transition-colors"
      :class="
        isActive(tab.name)
          ? 'text-cw-primary'
          : 'text-cw-text-faint hover:text-cw-text-muted'
      "
      @click="router.push({ name: tab.name })"
    >
      <span class="relative">
        <span :class="tab.icon" class="text-xl" />
        <span
          v-if="tab.name === 'conversations' && unreadCount"
          class="absolute -top-1 -right-2 min-w-4 h-4 px-1 flex items-center justify-center rounded-full bg-cw-primary text-cw-primary-foreground text-xxs font-semibold"
        >
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
      </span>
      <span class="text-xxs font-medium">{{ $t(tab.label) }}</span>
    </button>
  </nav>
</template>
