<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useHaptics } from 'dashboard/composables/useHaptics';
import { vHapticTap } from './hapticTap';

defineProps({
  activeTab: {
    type: Number,
    default: 1,
  },
});

const emit = defineEmits(['change']);

const { t } = useI18n();

const unreadCount = useMapGetter('notifications/getUnreadCount');

const tabs = computed(() => [
  {
    id: 0,
    label: t('MOBILE.TABS.INBOX'),
    icon: 'i-lucide-inbox',
    badge: unreadCount.value || 0,
  },
  {
    id: 1,
    label: t('MOBILE.TABS.CONVERSATIONS'),
    icon: 'i-lucide-message-circle',
    badge: 0,
  },
  {
    id: 2,
    label: t('MOBILE.TABS.SETTINGS'),
    icon: 'i-lucide-settings',
    badge: 0,
  },
]);

const { light } = useHaptics();

const onTabClick = tabId => {
  light();
  emit('change', tabId);
};
</script>

<template>
  <nav
    class="fixed bottom-0 left-0 right-0 z-50 flex items-stretch justify-around bg-white dark:bg-n-background border-t border-n-weak pb-[env(safe-area-inset-bottom)]"
  >
    <button
      v-for="tab in tabs"
      :key="tab.id"
      v-haptic-tap
      class="flex flex-col flex-1 items-center justify-center gap-0.5 py-2 transition-colors duration-150 relative"
      :class="
        activeTab === tab.id
          ? 'text-n-brand'
          : 'text-n-slate-10 active:text-n-slate-12'
      "
      @click="onTabClick(tab.id)"
    >
      <span class="relative">
        <span class="block size-6" :class="tab.icon" />
        <span
          v-if="tab.badge > 0"
          class="absolute -top-1.5 -right-2.5 flex items-center justify-center min-w-[18px] h-[18px] px-1 text-[10px] font-bold leading-none text-white bg-n-ruby-9 rounded-full"
        >
          {{ tab.badge > 99 ? '99+' : tab.badge }}
        </span>
      </span>
      <span class="text-[10px] font-medium leading-tight">
        {{ tab.label }}
      </span>
    </button>
  </nav>
</template>
