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
  <!-- Floating pill: content scrolls beneath it, so the panel keeps its full
       height and the widget loses the docked-tab-bar silhouette. -->
  <nav
    class="scroll-edge absolute inset-x-0 bottom-0 z-10 flex justify-center px-3 pb-3 pointer-events-none"
    :aria-label="$t('TABS.HOME')"
  >
    <div
      class="glass-layer surface-card relative flex items-stretch w-full gap-1 p-1 pointer-events-auto"
    >
      <button
        v-for="tab in tabs"
        :key="tab.name"
        type="button"
        class="relative flex flex-col items-center justify-center flex-1 gap-1 tab-height rounded-button transition-colors outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        :class="
          isActive(tab.name)
            ? 'bg-cw-primary-soft text-cw-primary'
            : 'text-cw-text-faint hover:text-cw-text-muted hover:bg-cw-surface'
        "
        @click="router.push({ name: tab.name })"
      >
        <span class="relative flex items-center justify-center">
          <span
            :class="isActive(tab.name) ? tab.activeIcon : tab.icon"
            class="icon-size"
          />
          <span
            v-if="tab.name === 'conversations' && unreadCount"
            class="absolute -top-1 -right-2.5 min-w-4 h-4 px-1 flex items-center justify-center rounded-full bg-cw-primary text-cw-primary-foreground text-xxs font-semibold ring-2 ring-cw-solid"
          >
            {{ unreadCount > 9 ? '9+' : unreadCount }}
          </span>
        </span>
        <span
          class="text-xs"
          :class="isActive(tab.name) ? 'font-520' : 'font-medium'"
        >
          {{ $t(tab.label) }}
        </span>
      </button>
    </div>
  </nav>
</template>
