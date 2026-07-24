<script setup>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';

const router = useRouter();
const { isAdmin } = useAdmin();
const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');

const showBillingButton = computed(
  () => isAdmin.value && isOnChatwootCloud.value
);

const openBilling = () => {
  router.push({ name: 'billing_settings_index' });
};

const toggleSupportWidgetVisibility = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggleBubbleVisibility('show');
  }
};

const toggleSupportWidget = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const setupListenerForWidgetEvent = () => {
  window.addEventListener('chatwoot:on-message', () => {
    toggleSupportWidgetVisibility();
  });
};

onMounted(() => {
  toggleSupportWidgetVisibility();
  setupListenerForWidgetEvent();
});
</script>

<template>
  <div class="items-center bg-n-slate-2 flex justify-center h-full w-full">
    <EmptyState
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE')"
    >
      <div class="flex justify-center gap-2">
        <NextButton
          v-if="showBillingButton"
          icon="i-lucide-credit-card"
          :label="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MANAGE_BILLING')"
          @click="openBilling"
        />
        <NextButton
          icon="i-lucide-life-buoy"
          :label="$t('SIDEBAR_ITEMS.CONTACT_SUPPORT')"
          :faded="showBillingButton"
          @click="toggleSupportWidget"
        />
      </div>
    </EmptyState>
  </div>
</template>
