<script setup>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const toggleSupportWidgetVisibility = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggleBubbleVisibility('show');
  }
};

const setupListenerForWidgetEvent = () => {
  window.addEventListener('chatwoot:on-message', () => {
    toggleSupportWidgetVisibility();
  });
};

const goToBilling = () => {
  router.push({ name: 'billing_settings_index' });
};

onMounted(() => {
  toggleSupportWidgetVisibility();
  setupListenerForWidgetEvent();
});
</script>

<template>
  <div
    class="items-center bg-n-slate-2 flex flex-col justify-center h-full w-full"
  >
    <EmptyState
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE')"
    />
    <button
      class="mt-4 px-4 py-2 bg-n-brand text-white rounded-lg text-sm font-medium hover:bg-n-brand/90 transition-colors"
      @click="goToBilling"
    >
      {{ $t('APP_GLOBAL.ACCOUNT_SUSPENDED.FIX_PAYMENT') }}
    </button>
  </div>
</template>
